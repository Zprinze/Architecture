`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:02:34 03/25/2016 
// Design Name: 
// Module Name:    Data_path 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`include "define.vh"
module Data_path(
		input wire clk,
		input wire rst,
		// debug control
		input wire cpu_rst,  // cpu reset signal
		input wire cpu_en,  // cpu enable signal
		// debug
		`ifdef DEBUG
		input wire [5:0] debug_addr,  // debug address
		output wire [31:0] debug_data,  // debug data
		`endif
		input  RegDst,
		input  ALUSrc_B,
		input  Jal,
		input  RegWrite,
		input  [1:0] DatatoReg,
		input  [1:0] Branch,
		input  [2:0] ALU_Control,
		input [25:0] inst_field,
		input [31:0] Data_in,
		output[31:0] ALU_out,
		output[31:0] Data_out,
		output[31:0] PC_out,
		output zero,
		output overflow 
		
    );
	wire[31:0] pc_4;
	wire[31:0] Imm_32;
	wire[31:0] branch_pc;
	wire[31:0] wt_addr_1;
	wire[31:0] wt_addr_2;
	wire[31:0] wt_data;
	wire[31:0] ALU_A;
	wire[31:0] ALU_B;
	wire[31:0] pc_next;
	wire[31:0] ALU_out_DUMMY;
	wire[31:0] Data_out_DUMMY;
	wire[31:0] PC_out_DUMMY;
	
	assign ALU_out[31:0] = ALU_out_DUMMY[31:0];
	assign Data_out[31:0] = Data_out_DUMMY[31:0];
	assign PC_out[31:0] = PC_out_DUMMY[31:0];
	
	/*/ data signals
	wire [31:0] inst_addr_next;
	wire [4:0] addr_rs, addr_rt, addr_rd;
	wire [31:0] data_rs, data_rt, data_imm;
	reg [31:0] opa, opb;
	wire [31:0] alu_out;
	wire rs_rt_equal;
	reg [4:0] regw_addr;
	reg [31:0] regw_data;
	//*/
	// debug
	`ifdef DEBUG
	wire [31:0] debug_data_reg;
	reg [31:0] debug_data_signal;
	
	always @(posedge clk) begin
		case (debug_addr[4:0])
			0: debug_data_signal <= 0;
			1: debug_data_signal <= {6'b0,inst_field};
			2: debug_data_signal <= 0;
			3: debug_data_signal <= 0;
			4: debug_data_signal <= 0;
			5: debug_data_signal <= 0;
			6: debug_data_signal <= 0;
			7: debug_data_signal <= 0;
			8: debug_data_signal <= {27'b0, inst_field[25:21]};
			9: debug_data_signal <= 0;//data_rs;
			10: debug_data_signal <= {27'b0, inst_field[20:16]};
			11: debug_data_signal <= 0;//data_rt;
			12: debug_data_signal <= 0;//data_imm;
			13: debug_data_signal <= 0;//opa;
			14: debug_data_signal <= 0;//opb;
			15: debug_data_signal <= ALU_out_DUMMY;
			16: debug_data_signal <= 0;
			17: debug_data_signal <= 0;
			18: debug_data_signal <= {19'b0, 1, 7'b0,1, 3'b0,0};//mem_wen};
			19: debug_data_signal <= ALU_out_DUMMY;
			20: debug_data_signal <= Data_in;
			21: debug_data_signal <= Data_out_DUMMY;
			22: debug_data_signal <= {27'b0, wt_addr_2[4:0]};
			23: debug_data_signal <= wt_data;
			default: debug_data_signal <= 32'hFFFF_FFFF;
		endcase
	end
	
	assign
		debug_data = debug_addr[5] ? debug_data_signal : debug_data_reg;
	`endif
	
	
	add_32  ALU_Branch (.a(pc_4[31:0]), 
							 .b({Imm_32[29:0], 2'b00}), 
							 .c(branch_pc[31:0]));
	
	add_32  ALU_PC_4 (.a(PC_out_DUMMY[31:0]), 
						  .b(32'b00000000_00000000_00000000_00000100), 
						  .c(pc_4[31:0]));
	
	Ext_32  Ext32 (.imm_16(inst_field[15:0]), 
					  .Imm_32(Imm_32[31:0]));
	
	mux2to1_5  mux1 (.a(5'b11111), 
						 .b(inst_field[20:16]), 
						 .sel(Jal), 
						 .o(wt_addr_1[4:0]));
	
	mux2to1_5  mux2 (.a(inst_field[15:11]), 
						 .b(wt_addr_1[4:0]), 
						 .sel(RegDst), 
						 .o(wt_addr_2[4:0]));
	
	mux4to1_32  mux3 (.a(ALU_out_DUMMY[31:0]), 
						  .b(Data_in[31:0]), 
						  .c({inst_field[15:0], 16'b00000000_00000000}), 
						  .d(pc_4[31:0]), 
						  .sel(DatatoReg[1:0]), 
						  .o(wt_data[31:0]));
	
	mux2to1_32  mux4 (.a(Imm_32[31:0]), 
						  .b(Data_out_DUMMY[31:0]), 
						  .sel(ALUSrc_B), 
						  .o(ALU_B[31:0]));
	
	mux4to1_32  mux5 (.a(pc_4[31:0]), 
						  .b(branch_pc[31:0]), 
						  .c({pc_4[31:28], inst_field[25:0], 2'b00}), 
						  .d(ALU_A[31:0]), 
						  .sel(Branch[1:0]), 
						  .o(pc_next[31:0]));
	
	ALU  U1 (.A(ALU_A[31:0]), 
				.ALU_operation(ALU_Control[2:0]), 
				.B(ALU_B[31:0]), 
				.overflow(), 
				.res(ALU_out_DUMMY[31:0]), 
				.zero(zero));
	
	Regs  U2 (.clk(clk), 
				.L_S(RegWrite && cpu_en), 
				.rst(rst), 
				.R_addr_A(inst_field[25:21]), 
				.R_addr_B(inst_field[20:16]), 
				.Wt_addr(wt_addr_2[4:0]), 
				.Wt_data(wt_data[31:0]), 
				.rdata_A(ALU_A[31:0]), 
				.rdata_B(Data_out_DUMMY[31:0]));
	
	Decode_pc_Int  U3 (.clk(clk),
				.cpu_en(cpu_en),
				.rst(cpu_rst),
				.INT(1'b0), 
				.pc_next(pc_next[31:0]), 
				.RFE(1'b0), 
				.pc(PC_out_DUMMY[31:0]));
	 
	

endmodule
