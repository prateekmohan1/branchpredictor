//
//--------------------------------------------------------------------------------
//          THIS FILE WAS AUTOMATICALLY GENERATED BY THE GENESIS2 ENGINE        
//  FOR MORE INFORMATION: OFER SHACHAM (CHIP GENESIS INC / STANFORD VLSI GROUP)
//    !! THIS VERSION OF GENESIS2 IS NOT FOR ANY COMMERCIAL USE !!
//     FOR COMMERCIAL LICENSE CONTACT SHACHAM@ALUMNI.STANFORD.EDU
//--------------------------------------------------------------------------------
//
//  
//	-----------------------------------------------
//	|            Genesis Release Info             |
//	|  $Change: 11904 $ --- $Date: 2013/08/03 $   |
//	-----------------------------------------------
//	
//
//  Source file: /afs/asu.edu/users/p/m/o/pmohan6/EEE591Brunhav/ProjPart4/Submission/primitives/alu.vp
//  Source template: alu
//
// --------------- Begin Pre-Generation Parameters Status Report ---------------
//
//	From 'generate' statement (priority=5):
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From Command Line input (priority=4):
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From XML input (priority=3):
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From Config File input (priority=2):
//
// ---------------- End Pre-Generation Pramameters Status Report ----------------

// alu.vp
// bitWidth (_GENESIS2_DECLARATION_PRIORITY_) = 32
//
module alu(
input logic nd_valid,
output logic nd_ready,
output logic qr_valid,
input logic ab_valid,
output logic ab_ready,
output logic z_valid,
input logic [19:0] opcode,
input logic [31:0] rs,
input logic [31:0] rt,
output logic [63:0] alu_out,
input logic clk,
input logic rst
);


//Decode input instr.
logic [19:0] op;
logic sign_bit;
logic [4:0] extend;
logic [31:0] inter;
logic [64:0] mult_out;
logic [31:0] div_quo_out;
logic [31:0] div_rem_out;

seqDiv  my_seqDiv(		//SeqDiv
.nd_valid(nd_valid),
.den(rt),
.num(rs),
.quo(div_quo_out),
.rem(div_rem_out),
.nd_ready(nd_ready),
.clk(clk),
.rst(rst),
.qr_valid(qr_valid)
);

seqMult  my_seqMult(		//SeqMult
.ab_valid(ab_valid),
.a(rs),
.b(rt),
.z(mult_out),
.ab_ready(ab_ready),
.clk(clk),
.rst(rst),
.z_valid(z_valid)
);

always_comb begin
op = opcode;
unique case( op)
	20'b10000000000000000000: begin						//ADD
							alu_out = rs + rt;
						end
	20'b01000000000000000000: begin						//AND
							alu_out = rs & rt; 		//(bit-wise)
						end
	20'b00100000000000000000: begin						//NOR
							alu_out = ~(rs | rt);
						end
	20'b00010000000000000000: begin						//OR
							alu_out = rs | rt;
						end
	20'b00001000000000000000: begin						//SLT
							if (rs[31] == 1'b1 && rt[31] == 1'b0) begin
								alu_out = 1;
							end
							else if (rs[31] == 1'b0 && rt[31] == 1'b1) begin
								alu_out = 0;
							end
							else if (rs[31] == 1'b0 && rt[31] == 1'b0) begin
								if (rs < rt) begin
									alu_out = 1;
								end
								else begin
									alu_out = 0;
								end
							end
							else begin
								//NEED TO ADD SOMETHING HERE
								alu_out = 0;
							end
						end
	20'b00000100000000000000: begin						//SUB
							alu_out = rs - rt;
						end
	20'b00000010000000000000: begin						//XOR
							alu_out = rs ^ rt;
						end
	20'b00000001000000000000: begin						//SRA
							sign_bit = rt[31];
							extend = 31-rs;
							inter = rt >>> rs;
							//alu_out = { {extend{sign_bit}},inter };
							alu_out = inter;
							
						end
	20'b00000000100000000000: begin						//JR
							alu_out = rs + rt;
						end
	20'b00000000010000000000: begin						//ADDI
							alu_out = rs + rt;
						end
	20'b00000000001000000000: begin						//ANDI
							alu_out = rs & rt;
						end
	20'b00000000000100000000: begin						//ORI
							alu_out = rs | rt;
						end
	20'b00000000000010000000: begin						//SLTI
							if (rs[31] == 1'b1 && rt[31] == 1'b0) begin
								alu_out = 1;
							end
							else if (rs[31] == 1'b0 && rt[31] == 1'b1) begin
								alu_out = 0;
							end
							else if (rs[31] == 1'b0 && rt[31] == 1'b0) begin
								if (rs < rt) begin
									alu_out = 1;
								end
								else begin
									alu_out = 0;
								end
							end
							else begin
								//NEED TO ADD SOMETHING HERE
								alu_out = 0;
							end
						end
	20'b00000000000001000000: begin					//XORI
							alu_out = rs ^ rt;
						end
	20'b00000000000000100000: begin						//LW
							alu_out = rs + rt;
						end
	20'b00000000000000001111: begin						//SB
							alu_out = rs + rt;
						end
	20'b00000000000000010000: begin						//SW
							alu_out = rs + rt;
						end
	20'b00000000000000001000: begin						//BEQ
							alu_out = rs + {14'b0,(rt<<2)};
						end
	20'b00000000000000000100: begin						//BGTZ
							alu_out = rs + {14'b0,(rt<<2)};
						end
	20'b00000000000000000010: begin						//BNE
							alu_out = rs + {14'b0,(rt<<2)};
						end
	20'b00000000000000000001: begin						//J
							alu_out = {rs[31:28],(rt<<2)};
						end
	20'b00000000000000000011: begin						//LUI
							alu_out = (rt<<16);
						end
	20'b00000000000000000111: begin						//SLL
							alu_out = rt << rs;
						end
	20'b00000000000000011111: begin						//MULT
							//ab_valid = 1;
							alu_out = mult_out;
						end
	20'b00000000000000111111: begin						//DIV
							alu_out[31:0] = div_quo_out;
							alu_out[63:32] = div_rem_out;
						end
	default: begin
		alu_out = 0;
	end
endcase


end

endmodule: alu
