`timescale 1ns / 1ps

module dp_addsub (
    input  [63:0] a,
    input  [63:0] b,
    input op,
    output reg [63:0] result
);

    // Constants for double precision
    localparam EXP_INF    = 11'b11111111111;
    localparam EXP_ZERO   = 11'b00000000000;
    localparam BIAS       = 1023;

    // Unpack inputs
    wire        sign_a = a[63];
    wire [10:0] exp_a  = a[62:52];
    wire [51:0] frac_a = a[51:0];

    wire        sign_b = b[63] ^ op;
    wire [10:0] exp_b  = b[62:52];
    wire [51:0] frac_b = b[51:0];

    // Special-case detection
    wire a_nan  = (exp_a == EXP_INF) && (frac_a != 0);
    wire b_nan  = (exp_b == EXP_INF) && (frac_b != 0);
    wire a_inf  = (exp_a == EXP_INF) && (frac_a == 0);
    wire b_inf  = (exp_b == EXP_INF) && (frac_b == 0);
    wire a_zero = (exp_a == EXP_ZERO) && (frac_a == 0);
    wire b_zero = (exp_b == EXP_ZERO) && (frac_b == 0);

    // Internal signals
    reg [52:0] man_a, man_b;
    reg        a_denorm, b_denorm;
    reg [10:0] expA_eff, expB_eff;
    reg [55:0] extA, extB;
    reg [55:0] alignedA, alignedB;
    reg [10:0] exp_align;
    integer    diff;
    reg [55:0] mask;
    reg        sticky;
    reg [56:0] sum;
    reg        op_sign;
    reg [53:0] candidate;
    reg        guard_bit, round_bit, sticky_bit;
    reg [10:0] final_exp;
    integer    shift_count;
    reg        found_one;
    reg [55:0] tmp;

    always @(*) begin
        // Default assignment
        result = 64'd0;

        // Special-case handling
        if (a_nan || b_nan) begin
            result = 64'h7FF8000000000000;  // Canonical NaN
        end else if (a_inf || b_inf) begin
            if (a_inf && b_inf && (sign_a != sign_b)) begin
                result = 64'h7FF8000000000000;  // Inf - Inf = NaN
            end else if (a_inf) begin
                result = {sign_a, EXP_INF, 52'b0};  // Return +/-Inf
            end else begin
                result = {sign_b, EXP_INF, 52'b0};  // Return +/-Inf
            end
        end else if (a_zero && b_zero) begin
            result = {sign_a & sign_b, 63'b0};  // Signed zero
        end else begin
            // Prepare mantissas with hidden bit
            a_denorm = (exp_a == EXP_ZERO);
            b_denorm = (exp_b == EXP_ZERO);
            man_a = a_denorm ? {1'b0, frac_a} : {1'b1, frac_a};
            man_b = b_denorm ? {1'b0, frac_b} : {1'b1, frac_b};
            expA_eff = a_denorm ? 11'd1 : exp_a;
            expB_eff = b_denorm ? 11'd1 : exp_b;
            extA = {man_a, 3'b000};  // 56-bit extended with guard/round/sticky
            extB = {man_b, 3'b000};

            // Align exponents (shift smaller exponent number)
            sticky = 0;
            if (expA_eff >= expB_eff) begin
                diff = expA_eff - expB_eff;
                exp_align = expA_eff;
                alignedA = extA;
                if (diff >= 56) begin
                    sticky = |extB;
                    alignedB = 0;
                end else begin
                    mask = (1 << diff) - 1;
                    sticky = |(extB & mask);
                    tmp = extB >> diff;
                    alignedB = tmp;
                    alignedB[0] = alignedB[0] | sticky;
                end
            end else begin
                diff = expB_eff - expA_eff;
                exp_align = expB_eff;
                alignedB = extB;
                if (diff >= 56) begin
                    sticky = |extA;
                    alignedA = 0;
                end else begin
                    mask = (1 << diff) - 1;
                    sticky = |(extA & mask);
                    tmp = extA >> diff;
                    alignedA = tmp;
                    alignedA[0] = alignedA[0] | sticky;
                end
            end

            // Add/Subtract based on signs
            if (sign_a == sign_b) begin
                sum = {1'b0, alignedA} + {1'b0, alignedB};
                op_sign = sign_a;
            end else begin
                if (alignedA >= alignedB) begin
                    sum = {1'b0, alignedA} - {1'b0, alignedB};
                    op_sign = sign_a;
                end else begin
                    sum = {1'b0, alignedB} - {1'b0, alignedA};
                    op_sign = sign_b;
                end
            end

            // Handle zero result
            if (sum == 0) begin
                result = {op_sign, 63'b0};
            end else begin
                // Normalization and exponent adjustment
                final_exp = exp_align;
                
                // Handle carry-out
                if (sum[56]) begin
                    sum = sum >> 1;
                    final_exp = final_exp + 1;
                end 
                // Normalize leading zeros - only when exponent > 1
                else begin
                    found_one = 0;
                    for (shift_count = 0; shift_count < 55; shift_count = shift_count + 1) begin
                        if (!found_one && (sum[55] == 0) && (final_exp > 1)) begin
                            sum = sum << 1;
                            final_exp = final_exp - 1;
                        end else begin
                            found_one = 1;
                        end
                    end
                end

                // Critical fix for denormal results
                // Convert to denormal if exponent is 1 but no leading 1
                if (final_exp == 1 && sum[55] == 0) begin
                    final_exp = 0;
                end

                // Prepare for rounding
                candidate = {1'b0, sum[55:3]};
                guard_bit = sum[2];
                round_bit = sum[1];
                sticky_bit = sum[0] | sticky;  // Include alignment sticky

                // Round to nearest even (ties to even)
                if (guard_bit && (round_bit || sticky_bit || candidate[0])) begin
                    candidate = candidate + 1;
                    // Handle mantissa overflow after rounding
                    if (candidate[53]) begin
                        candidate = candidate >> 1;
                        final_exp = final_exp + 1;
                    end
                end

                // Final result assembly
                if (final_exp >= EXP_INF) begin
                    result = {op_sign, EXP_INF, 52'b0};  // Overflow to infinity
                end else if (final_exp == 0) begin  // Subnormal result
                    result = {op_sign, EXP_ZERO, candidate[51:0]};
                end else begin  // Normal result
                    result = {op_sign, final_exp, candidate[51:0]};
                end
            end
        end
    end
endmodule
