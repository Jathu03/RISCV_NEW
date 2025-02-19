`timescale 1ns / 1ps

module tb_floating_point_adder;

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] a;
    reg [31:0] b;

    // Outputs
    wire [31:0] result;

    // Instantiate the Unit Under Test (UUT)
    floating_point_adder uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(result)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        a = 32'b0;
        b = 32'b0;

        // Apply reset
        #10;
        reset = 0;

        // Test Case 1: Add 1.5 + 2.25
        #10;
        a = 32'h3FC00000; // 1.5 in IEEE 754
        b = 32'h40080000; // 2.25 in IEEE 754
        #20;
        $display("Test 1: a=%h, b=%h -> result=%h", a, b, result);

        // Test Case 2: Add -3.5 + 1.25
        #10;
        a = 32'hC0600000; // -3.5 in IEEE 754
        b = 32'h3FA00000; // 1.25 in IEEE 754
        #20;
        $display("Test 2: a=%h, b=%h -> result=%h", a, b, result);

        // Test Case 3: Add 0.5 + 0.25
        #10;
        a = 32'h3F000000; // 0.5 in IEEE 754
        b = 32'h3E800000; // 0.25 in IEEE 754
        #20;
        $display("Test 3: a=%h, b=%h -> result=%h", a, b, result);

        // End simulation
        #10;
        $stop;
    end
endmodule
