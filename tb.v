`timescale 1ns / 1ps

module tb();

    // Inputs
    reg [63:0] a, b;
    reg op;

    // Output
    wire [63:0] result;

    // Instantiate the DUT
    dp_addsub uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

    // Helper task for displaying binary and expected
    task print_case;
        input [63:0] in_a;
        input [63:0] in_b;
        input in_op;
        input [63:0] expected;
        begin
            a = in_a;
            b = in_b;
            op = in_op;
            #10;
            $display("a = %h, b = %h => result = %h (expected = %h)", in_a, in_b, result, expected);
        end
    endtask

    initial begin
        $display("Starting Double-Precision Floating-Point Addition Testbench");

        // Format: print_case(a, b, expected_result);

        // 1. Basic addition
        print_case(64'h3FF0000000000000, 64'h3FF0000000000000, 1'b0, 64'h4000000000000000); 
        print_case(64'h3FF0000000000000, 64'h3FF0000000000000, 1'b1, 64'h4000000000000000); 


        // 2. Different exponents
        print_case(64'h3FF0000000000000, 64'h4000000000000000, 1'b0, 64'h4008000000000000);
        print_case(64'h3FF0000000000000, 64'h4000000000000000, 1'b1, 64'h4008000000000000); 

        // 3. Negative numbers
        print_case(64'hBFF0000000000000, 64'h4000000000000000, 1'b0, 64'h3FF0000000000000); 
        print_case(64'hBFF0000000000000, 64'h4000000000000000, 1'b1, 64'h3FF0000000000000); 

        // 4. Subnormal numbers
        print_case(64'h0000000000000001, 64'h0000000000000001, 1'b0, 64'h0000000000000002); 
        print_case(64'h0000000000000001, 64'h0000000000000001, 1'b1, 64'h0000000000000002); 

        // 5. Overflow to infinity
        print_case(64'h7FEFFFFFFFFFFFFF, 64'h7FEFFFFFFFFFFFFF, 1'b0, 64'h7FF0000000000000);
        print_case(64'h7FEFFFFFFFFFFFFF, 64'h7FEFFFFFFFFFFFFF, 1'b1, 64'h7FF0000000000000);

        // 6. NaN handling
        print_case(64'h7FF0000000000001, 64'h3FF0000000000000,1'b0, 64'h7FF8000000000000);
        print_case(64'h7FF0000000000001, 64'h3FF0000000000000,1'b1, 64'h7FF8000000000000);

        // 7. Infinity handling
        print_case(64'h7FF0000000000000, 64'h7FF0000000000000,1'b0, 64'h7FF0000000000000); 
        print_case(64'h7FF0000000000000, 64'h7FF0000000000000,1'b1, 64'h7FF0000000000000);

        // 8. Inf - Inf = NaN
        print_case(64'h7FF0000000000000, 64'hFFF0000000000000,1'b0, 64'h7FF8000000000000); 
        print_case(64'h7FF0000000000000, 64'hFFF0000000000000,1'b1, 64'h7FF8000000000000);

        // 9. Rounding test
        print_case(64'h3FF0000000000001, 64'h3FF0000000000001,1'b0, 64'h4000000000000001); 
        print_case(64'h3FF0000000000001, 64'h3FF0000000000001,1'b1, 64'h4000000000000001);

        // 10. Cancellation
        print_case(64'h3FF0000000000000, 64'hBFF0000000000000,1'b0, 64'h0000000000000000); 
        print_case(64'h3FF0000000000000, 64'hBFF0000000000000,1'b1, 64'h0000000000000000);

        // 11. Large exponent difference
        print_case(64'h412E848000000000, 64'h3EB0C6F7A0B5ED8D,1'b0, 64'h412e84800000218e); 
        print_case(64'h412E848000000000, 64'h3EB0C6F7A0B5ED8D,1'b1, 64'h412e84800000218e);

        // 12. Small numbers
        print_case(64'h3EE4F8B588E368F1, 64'h3EE4F8B588E368F1,1'b0, 64'h3EF4F8B588E368F1); 
        print_case(64'h3EE4F8B588E368F1, 64'h3EE4F8B588E368F1,1'b1, 64'h3EF4F8B588E368F1);

        // 13. Mixed signs
        print_case(64'h4010000000000000, 64'hC008000000000000,1'b0, 64'h3ff0000000000000); 
        print_case(64'h4010000000000000, 64'hC008000000000000,1'b1, 64'h3ff0000000000000);

        // 14. Denormal result
        print_case(64'h0008000000000000, 64'h0008000000000000,1'b0, 64'h0010000000000000); 
        print_case(64'h0008000000000000, 64'h0008000000000000,1'b1, 64'h0010000000000000);

        // 15. Rounding to even
        print_case(64'h3FF0000000000008, 64'h3FF0000000000008,1'b0, 64'h4000000000000008); 
        print_case(64'h3FF0000000000008, 64'h3FF0000000000008,1'b1, 64'h4000000000000008);

        // 16. Very large numbers
        print_case(64'h7FE0000000000000, 64'h7FE0000000000000,1'b0, 64'h7FF0000000000000); 
        print_case(64'h7FE0000000000000, 64'h7FE0000000000000,1'b1, 64'h7FF0000000000000);

        // 17. Zero handling
        print_case(64'h0000000000000000, 64'h0000000000000000,1'b0, 64'h0000000000000000); 
        print_case(64'h0000000000000000, 64'h0000000000000000,1'b1, 64'h0000000000000000);

        // 18. Negative zero
        print_case(64'h8000000000000000, 64'h0000000000000000,1'b0, 64'h0000000000000000); 
        print_case(64'h8000000000000000, 64'h0000000000000000,1'b1, 64'h0000000000000000);

        // 19. Different magnitudes
        print_case(64'h4034000000000000, 64'h3FB999999999999A,1'b0, 64'h403419999999999a);
        print_case(64'h4034000000000000, 64'h3FB999999999999A,1'b1, 64'h403419999999999a); 

        // 20. Random test case 1
        print_case(64'h3FD5555555555555, 64'h3FC999999999999A,1'b0, 64'h3fe1111111111111);
        print_case(64'h3FD5555555555555, 64'h3FC999999999999A,1'b1, 64'h3fe1111111111111); 

        // 21. Random test case 2
        print_case(64'h400921FB54442D18, 64'h400921FB54442D18,1'b0, 64'h401921FB54442D18);
        print_case(64'h400921FB54442D18, 64'h400921FB54442D18,1'b1, 64'h401921FB54442D18); 

        // 22. Random test case 3
        print_case(64'h3FF199999999999A, 64'h3FF3333333333333,1'b0, 64'h4002666666666666);
        print_case(64'h3FF199999999999A, 64'h3FF3333333333333,1'b1, 64'h4002666666666666); 

        // 23. Random test case 4
        print_case(64'h405EDD2F1A9FBE77, 64'hC05EDD2F1A9FBE77,1'b0, 64'h0000000000000000);
        print_case(64'h405EDD2F1A9FBE77, 64'hC05EDD2F1A9FBE77,1'b1, 64'h0000000000000000);

        // 24. Random test case 5
        print_case(64'h3FF0000000000000, 64'h3FB999999999999A,1'b0, 64'h3FF199999999999A);
        print_case(64'h3FF0000000000000, 64'h3FB999999999999A,1'b1, 64'h3FF199999999999A); 

        // 25. Random test case 6
        print_case(64'h4000000000000000, 64'h4008000000000000,1'b0, 64'h4014000000000000);
        print_case(64'h4000000000000000, 64'h4008000000000000,1'b1, 64'h4014000000000000); 
        
        // 26. Mixed signs and small magnitude
        print_case(64'h3FD5555555555555, 64'hC00999999999999A,1'b0, 64'h000CCCCCCCCCCCCD);
        print_case(64'h3FD5555555555555, 64'hC00999999999999A,1'b1, 64'h000CCCCCCCCCCCCD); 
        
        // 27. Near overflow with large magnitude
        print_case(64'h7FE0000000000000, 64'h7FDFFFFFFFFFFFFF,1'b0, 64'h7FF0000000000000);
        print_case(64'h7FE0000000000000, 64'h7FDFFFFFFFFFFFFF,1'b1, 64'h7FF0000000000000); 
        
        // 28. Very small positive and negative numbers
        print_case(64'h0010000000000000, 64'hFFF0000000000000,1'b0, 64'h0000000000000000);
        print_case(64'h0010000000000000, 64'hFFF0000000000000,1'b1, 64'h0000000000000000); 
        
        // 29. Numbers close to zero
        print_case(64'h0008000000000000, 64'h0008000000000001,1'b0, 64'h0008000000000001);
        print_case(64'h0008000000000000, 64'h0008000000000001,1'b1, 64'h0008000000000001); 
        
        // 30. Large difference, same sign
        print_case(64'h412E848000000000, 64'hC12E848000000000,1'b0, 64'h4000000000000000);
        print_case(64'h412E848000000000, 64'hC12E848000000000,1'b1, 64'h4000000000000000); 
        
        // 31. Large difference, opposite signs
        print_case(64'h412E848000000000, 64'hC12E848000000000,1'b0, 64'h4012E84800000000);
        print_case(64'h412E848000000000, 64'hC12E848000000000,1'b1, 64'h4012E84800000000);
        
        // 32. Numbers adding to subnormal
        print_case(64'h3FEFFFFFFFFFFFFF, 64'h3FF0000000000000,1'b0, 64'h3FEFFFFFFFFFFFFE);
        print_case(64'h3FEFFFFFFFFFFFFF, 64'h3FF0000000000000,1'b1, 64'h3FEFFFFFFFFFFFFE); 
        
        // 33. Numbers creating a rounding up
        print_case(64'h3FF0000000000000, 64'h3FEFFFFFFFFFFFFF,1'b0, 64'h4000000000000000);
        print_case(64'h3FF0000000000000, 64'h3FEFFFFFFFFFFFFF,1'b1, 64'h4000000000000000); 
        
        // 34. Numbers creating a rounding down
        print_case(64'h3FF0000000000000, 64'h3FF0000000000001,1'b0, 64'h4000000000000000);
        print_case(64'h3FF0000000000000, 64'h3FF0000000000001,1'b1, 64'h4000000000000000); 
        
        // 35. Numbers creating an underflow
        print_case(64'h0000000000000001, 64'h0000000000000002,1'b0, 64'h0000000000000000);
        print_case(64'h0000000000000001, 64'h0000000000000002,1'b1, 64'h0000000000000000); 
        
        // 36. Numbers creating an overflow
        print_case(64'h7FF0000000000000, 64'h3FF0000000000000,1'b0, 64'h7FF0000000000000);
        print_case(64'h7FF0000000000000, 64'h3FF0000000000000,1'b1, 64'h7FF0000000000000);
        
        // 37. Numbers adding to a NaN
        print_case(64'h7FF0000000000000, 64'h7FF0000000000000,1'b0, 64'h7FF8000000000000);
        print_case(64'h7FF0000000000000, 64'h7FF0000000000000,1'b1, 64'h7FF8000000000000); 
        
        // 38. Numbers creating a cancellation to zero
        print_case(64'h3FF0000000000000, 64'hBFF0000000000000,1'b0, 64'h0000000000000000);
        print_case(64'h3FF0000000000000, 64'hBFF0000000000000,1'b1, 64'h0000000000000000); 
        
        // 39. Numbers creating a cancellation to negative zero
        print_case(64'hBFF0000000000000, 64'h3FF0000000000000,1'b0, 64'h0000000000000000);
        print_case(64'hBFF0000000000000, 64'h3FF0000000000000,1'b1, 64'h0000000000000000); 
        
        // 40. Numbers creating a subnormal result
        print_case(64'h0008000000000000, 64'h0008000000000000,1'b0, 64'h0010000000000000);
        print_case(64'h0008000000000000, 64'h0008000000000000,1'b1, 64'h0010000000000000); 

        $display("Testbench complete.");
        $finish;
    end

endmodule
