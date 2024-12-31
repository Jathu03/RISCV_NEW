`include "controls.sv"

module controller #(parameter CTRL_SIZE = 21)(
	input logic clk, rstn, ex_no_stay,	// External signal for not jumping
	input logic [31:0] instruction,
	output logic [CTRL_SIZE-1:0] ctrl_signals
);
	// Control store
	localparam W_I = 9;	// size of memory address
	localparam W_C = CTRL_SIZE + 9;	// size of microinstruction
	
	logic [2**W_I-1:0][0:W_C-1] control_store;
	
	/* Make the control address */
	logic [8:0] ctrl_addr;
	logic [6:0] opcode;
	logic [2:0] func3;
	
	assign opcode = instruction[6:0];
	assign func3 = instruction[14:12];
	
	assign ctrl_addr[8:4] = instruction[6:2];
	
	always_comb begin
		if (opcode == `TYPE_R ||	
			(opcode == `TYPE_I_COMP && func3 == 3'b101))
			ctrl_addr[0] = instruction[30];
		else
			ctrl_addr[0] = 1'b0;
			
		if (opcode == `TYPE_R ||
			 opcode == `TYPE_I_COMP ||
			 opcode == `TYPE_I_LOAD ||
		    opcode == `TYPE_I_JALR ||
			 opcode == `TYPE_S ||
			 opcode == `TYPE_SB )
			ctrl_addr[3:1] = func3;
		else
			ctrl_addr[3:1] = 3'b0;
	end
	
	/* Next address logic */
	logic stay;
	logic [8:0] next_addr;
	logic [W_C-1:0] cur_ctrl;
	
	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			stay <= 1'b0;
			next_addr <= 9'b0;
		end else begin
			stay <= (cur_ctrl[12] & (~ex_no_stay));
			next_addr <= cur_ctrl[8:0];
		end
	end
	
	assign cur_ctrl = stay? control_store[next_addr] : control_store[ctrl_addr];
	assign ctrl_signals = cur_ctrl[W_C-1:9];
	
	/* microinstructions */
	// format:                     		  WEN	   ALUSEL   ALUB	ALUA	MEMW	MEMR	LST      LU    WSEL	   BT		   STY	MEMST	CEN	CSEL	NEXT			
	assign control_store[9'b011000000] = {1'b1,	4'b0000,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // add
	assign control_store[9'b011000001] = {1'b1,	4'b0001,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // sub
	assign control_store[9'b011000010] = {1'b1,	4'b0010,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // sll
	assign control_store[9'b011000100] = {1'b1,	4'b1000,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // slt
	assign control_store[9'b011000110] = {1'b1,	4'b1001,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // sltu
	assign control_store[9'b011001000] = {1'b1,	4'b0111,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // xor
	assign control_store[9'b011001010] = {1'b1,	4'b0011,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // srl
	assign control_store[9'b011001011] = {1'b1,	4'b0100,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // sra
	assign control_store[9'b011001100] = {1'b1,	4'b0110,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // or
	assign control_store[9'b011001110] = {1'b1,	4'b0101,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // and
	assign control_store[9'b011001111] = {1'b1,	4'b1100,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // mul
	
	assign control_store[9'b001000000] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // addi
	assign control_store[9'b001000100] = {1'b1,	4'b1000,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // slti
	assign control_store[9'b001000110] = {1'b1,	4'b1001,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // sltiu
	assign control_store[9'b001001000] = {1'b1,	4'b0111,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // xori
	assign control_store[9'b001001100] = {1'b1,	4'b0110,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // ori
	assign control_store[9'b001001110] = {1'b1,	4'b0101,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // andi
	assign control_store[9'b001000010] = {1'b1,	4'b0010,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // slli
	assign control_store[9'b001001010] = {1'b1,	4'b0011,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // srli
	assign control_store[9'b001001011] = {1'b1,	4'b0100,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // srai
	
	assign control_store[9'b011010000] = {1'b1,	4'b1011,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // lui
	assign control_store[9'b001010000] = {1'b1,	4'b0000,	1'b1,	1'b1,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // auipc
	
	assign control_store[9'b000000000] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b00,	1'b0,	2'b01,	3'b000,	1'b1,	1'b0,	1'b0,	1'b0,	9'b000000001}; // lb
	assign control_store[9'b000000010] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b01,	1'b0,	2'b01,	3'b000,	1'b1,	1'b0,	1'b0,	1'b0,	9'b000000011}; // lh
	assign control_store[9'b000000100] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b11,	1'b0,	2'b01,	3'b000,	1'b1,	1'b0,	1'b0,	1'b0,	9'b000000101}; // lw
	assign control_store[9'b000001000] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b00,	1'b1,	2'b01,	3'b000,	1'b1,	1'b0,	1'b0,	1'b0,	9'b000001001}; // lbu
	assign control_store[9'b000001010] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b01,	1'b1,	2'b01,	3'b000,	1'b1,	1'b0,	1'b0,	1'b0,	9'b000001011}; // lhu
	
	assign control_store[9'b010000000] = {1'b0,	4'b0000,	1'b1,	1'b0,	1'b1,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b1,	1'b0,	1'b0,	1'b0,	9'b010000001}; // sb
	assign control_store[9'b010000010] = {1'b0,	4'b0000,	1'b1,	1'b0,	1'b1,	1'b0,	2'b01,	1'b0,	2'b00,	3'b000,	1'b1,	1'b0,	1'b0,	1'b0,	9'b010000011}; // sh
	assign control_store[9'b010000100] = {1'b0,	4'b0000,	1'b1,	1'b0,	1'b1,	1'b0,	2'b11,	1'b0,	2'b00,	3'b000,	1'b1,	1'b0,	1'b0,	1'b0,	9'b010000101}; // sw
	
	assign control_store[9'b110000000] = {1'b0,	4'b0001,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b011,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // beq
	assign control_store[9'b110000010] = {1'b0,	4'b0001,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b100,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // bne
	assign control_store[9'b110001000] = {1'b0,	4'b1000,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b101,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // blt
	assign control_store[9'b110001010] = {1'b0,	4'b1000,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b110,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // bge
	assign control_store[9'b110001100] = {1'b0,	4'b1001,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b101,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // bltu
	assign control_store[9'b110001110] = {1'b0,	4'b1001,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b00,	3'b110,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // bgeu
	
	assign control_store[9'b110110000] = {1'b1,	4'b0000,	1'b0,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b10,	3'b001,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // jal
	assign control_store[9'b110010000] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b0,	2'b00,	1'b0,	2'b10,	3'b010,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // jalr
	
	assign control_store[9'b000100000] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b00,	1'b1,	2'b01,	3'b000,	1'b1,	1'b0,	1'b0,	1'b1,	9'b000100001}; // memcp
	assign control_store[9'b000100001] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b00,	1'b1,	2'b01,	3'b000,	1'b1,	1'b0,	1'b0,	1'b1,	9'b000100010}; // memcp2
	assign control_store[9'b000100010] = {1'b0,	4'b0000,	1'b1,	1'b0,	1'b1,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b1,	1'b1,	1'b0,	1'b1,	9'b000100011}; // memcp3
	assign control_store[9'b000100011] = {1'b0,	4'b0000,	1'b1,	1'b0,	1'b1,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b1,	1'b1,	1'b1,	1'b1,	9'b000100000}; // memcp4

	
	// For load and store, stay idle for another clock cycle with the same microinstructions
	assign control_store[9'b000000001] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b00,	1'b0,	2'b01,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // lb
	assign control_store[9'b000000011] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b01,	1'b0,	2'b01,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // lh
	assign control_store[9'b000000101] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b11,	1'b0,	2'b01,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // lw
	assign control_store[9'b000001001] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b00,	1'b1,	2'b01,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // lbu
	assign control_store[9'b000001011] = {1'b1,	4'b0000,	1'b1,	1'b0,	1'b0,	1'b1,	2'b01,	1'b1,	2'b01,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // lhu
	
	assign control_store[9'b010000001] = {1'b0,	4'b0000,	1'b1,	1'b0,	1'b1,	1'b0,	2'b00,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // sb
	assign control_store[9'b010000011] = {1'b0,	4'b0000,	1'b1,	1'b0,	1'b1,	1'b0,	2'b01,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // sh
	assign control_store[9'b010000101] = {1'b0,	4'b0000,	1'b1,	1'b0,	1'b1,	1'b0,	2'b11,	1'b0,	2'b00,	3'b000,	1'b0,	1'b0,	1'b0,	1'b0,	9'b000000000}; // sw
	
endmodule

// module controller (
//     input wire clk,
//     input wire reset,
//     input wire [31:0] instruction,
//     output reg [31:0] ctrl_signals
// );

//     // Parameterized constants for instruction types and opcodes
//     localparam TYPE_R = 3'b000;
//     localparam TYPE_I_COMP = 3'b001;
//     localparam TYPE_I_LOAD = 3'b010;
//     localparam TYPE_S = 3'b011;
//     localparam TYPE_B = 3'b100;
//     localparam TYPE_J = 3'b101;

//     // Control store parameters
//     localparam CTRL_STORE_SIZE = 64;
//     localparam CTRL_WIDTH = 32;

//     // Control store declaration
//     reg [CTRL_WIDTH-1:0] ctrl_store [0:CTRL_STORE_SIZE-1];

//     // Control address generation signals
//     reg [5:0] ctrl_addr;
//     reg [5:0] next_addr;
//     reg stay;

//     // Internal signal to hold the current control word
//     reg [CTRL_WIDTH-1:0] cur_ctrl;

//     // Initialize control store
//     initial begin
//         ctrl_store[6'b000000] = 32'b00000000000000000000000000000000; // NOP
//         ctrl_store[6'b000001] = 32'b00000000000000000000000000000001; // ADD
//         ctrl_store[6'b000010] = 32'b00000000000000000000000000000010; // SUB
//         ctrl_store[6'b000011] = 32'b00000000000000000000000000000100; // LW
//         ctrl_store[6'b000100] = 32'b00000000000000000000000000001000; // SW
//         ctrl_store[6'b000101] = 32'b00000000000000000000000000010000; // BEQ
//         ctrl_store[6'b000110] = 32'b00000000000000000000000000100000; // BNE
//         ctrl_store[6'b000111] = 32'b00000000000000000000000001000000; // JAL
//         // Add more microinstructions as needed...
//     end

//     // Opcode and function field extraction
//     wire [6:0] opcode = instruction[6:0];
//     wire [2:0] func3 = instruction[14:12];
//     wire func7 = instruction[30];

//     // Control address computation
//     always @(*) begin
//         case (opcode)
//             7'b0110011: ctrl_addr = {TYPE_R, func3}; // R-type instructions
//             7'b0010011: ctrl_addr = {TYPE_I_COMP, func3}; // I-type (computational)
//             7'b0000011: ctrl_addr = {TYPE_I_LOAD, func3}; // I-type (load)
//             7'b0100011: ctrl_addr = {TYPE_S, func3}; // S-type (store)
//             7'b1100011: ctrl_addr = {TYPE_B, func3}; // B-type (branch)
//             7'b1101111: ctrl_addr = {TYPE_J, 3'b000}; // J-type (JAL)
//             default: ctrl_addr = 6'b000000; // Default to NOP
//         endcase
//     end

//     // Control signal assignment
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             cur_ctrl <= ctrl_store[0]; // Reset to NOP
//         end else begin
//             if (stay)
//                 cur_ctrl <= ctrl_store[next_addr];
//             else
//                 cur_ctrl <= ctrl_store[ctrl_addr];
//         end
//     end

//     // Extract control signals from the control word
//     always @(*) begin
//         ctrl_signals = cur_ctrl[31:0];
//     end

// endmodule


