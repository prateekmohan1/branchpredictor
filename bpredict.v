module bpredict
	#(parameter PC_SIZE=32,
	  parameter BHR_DATA_SIZE=7,
	  parameter PHT_DATA_SIZE=2,
	  parameter ADDR_SIZE=32)
	(
	input logic [ADDR_SIZE-1:0] pc,
	input logic [ADDR_SIZE-1:0] immedval,			//This is the value of the immediate (in case you have to branch, you add this to PC)
	input logic branch_equality,					//This specifies if the branch evaluated to T or F in REG stage
	input logic is_branch,							//This specifies if the command in REG stage is a branch
	input logic clk, 
	input logic rst,
	output logic [ADDR_SIZE-1:0] address,
	output logic result,							//If this is 1, you had hit in BTB
	output logic PC_choose,
	output logic prediction							//If this is 1, you predicted it taken. If 0, you predicted not taken
	);

	//Logic for the output of BHR
	logic [BHR_DATA_SIZE-1:0] BHR_dataout;
	
	//Logic for input of PHT 
	logic [BHR_DATA_SIZE-1:0] PHT_address, PHT_waddress;
	logic [PHT_DATA_SIZE-1:0] PHT_dataout;

	logic [ADDR_SIZE-1:0] targetAddr;

	//You need to flop the PC value twice
	logic [PC_SIZE-1:0] pc_f1, pc_f2, pc_neg;

	//You need to flop the addr_size twice
	logic [ADDR_SIZE-1:0] immedval_f1, immedval_f2;

	//You need to flop the BHRout twice
	logic [BHR_DATA_SIZE-1:0] BHR_dataout_f1, BHR_dataout_f2;

	//You need to flop the PHT_dataout twice
	logic [PHT_DATA_SIZE-1:0] PHT_dataout_f1, PHT_dataout_f2;

	logic [BHR_DATA_SIZE-1:0] BHR_wData;
	logic [ADDR_SIZE-1:0] oldBTBaddress;
	logic [PHT_DATA_SIZE-1:0] updated_state;

	//'result' variable to check if you have a hit in BTB and branch taken
	//logic result;

	//'isHit' to check if the target address is in BTB
	logic isHit, isHit_posedge;

	logic rdEn, wrEn;
	logic BHR_busy, PHT_busy, BTB_busy;
	//logic pc_neg;

	logic roll_back;

	always_ff @(posedge clk) begin
		if (~rst) begin
			PC_choose <= 0;
		end
		else begin
			if (result == 1) begin
				PC_choose <= 1;
			end
			else begin
				PC_choose <= 0;
			end
		end
	end

	always_ff @(posedge clk) begin
		pc_neg <= pc;
	end

	always_comb begin
		if (is_branch == 1 && branch_equality == 1 && result == 1) begin
			roll_back = 0;
		end
		else if (is_branch == 1 && branch_equality == 0 && result == 1) begin
			roll_back = 1;
		end
		else begin
			roll_back = 0;
		end
	end

	//stage_check = 0 means you are in IF stage
	//stage_check = 1 means you are in ID stage
	always_comb begin
		if (is_branch == 1) begin
			rdEn = 1;
			wrEn = 1;
		end
		else begin
			rdEn = 1;
			wrEn = 0;
		end
	end

	assign result = isHit;

	always_comb begin
		//You check the most significant bit to see if the branch is taken or not
		if (isHit) begin
			if (PHT_dataout[PHT_DATA_SIZE-1] === 1'bx) begin
				prediction = 1;
			end
			else if (PHT_dataout[PHT_DATA_SIZE-1] === 1'b1) begin
				prediction = 1;
			end
			else begin
				prediction = 0;
			end
		end
		//if (PHT_dataout[PHT_DATA_SIZE-1] === 1'bx) begin
		//	if (isHit) begin
		//		result = 1;
		//	end
		//	else begin
		//		result = 0;
		//	end
		//end
		//else begin
		//	if (PHT_dataout[PHT_DATA_SIZE-1] === 1'b1 && isHit) begin
		//		result = 1;
		//	end
		//	else begin
		//		result = 0;
		//	end
		//end
	end

	always_ff @ (posedge clk) begin
		if (isHit == 1) begin
			isHit_posedge <= 1;
		end
		else begin
			isHit_posedge <= 0;
		end
	end

	always_comb begin
		if (isHit) begin
			if (prediction == 0) begin
				address = pc_f1 + 4;
			end
			else begin
				address = targetAddr;
			end
		end
	end

	//Make new state for the PHT 
	always_comb begin
		if (branch_equality == 1 && is_branch == 1) begin
			if (PHT_dataout_f2 === {PHT_DATA_SIZE{1'bx}}) begin
				updated_state = 2'b11;
			end
			else if (PHT_dataout_f2 !== {PHT_DATA_SIZE{1'b1}}) begin
				updated_state = PHT_dataout_f2 + 1;
			end
			else if (PHT_dataout_f2 === {PHT_DATA_SIZE{1'b1}}) begin
				updated_state = 2'b11;
			end
		end
		else if (branch_equality == 0 && is_branch == 1) begin
			if (PHT_dataout_f2 === {PHT_DATA_SIZE{1'bx}}) begin
				updated_state = 2'b11;
			end
			else if (PHT_dataout_f2 !== {PHT_DATA_SIZE{1'b0}}) begin
				updated_state = PHT_dataout_f2 - 1;
			end
			else if (PHT_dataout_f2 === {PHT_DATA_SIZE{1'b0}}) begin
				updated_state = 2'b00;
			end
		end
	end


	//Assign the wrData into the BTB
	//Assign the wrData into the BHR
	always_comb begin
		if (is_branch == 1) begin
			oldBTBaddress = pc_f2 + immedval_f1;
		end
		if (branch_equality == 1 && is_branch == 1) begin
			if (BHR_dataout_f2 === {BHR_DATA_SIZE{1'bx}}) begin
				BHR_wData = {{{BHR_DATA_SIZE-1}{1'b0}},1'b1};
			end
			else begin
				BHR_wData = {BHR_dataout_f2[BHR_DATA_SIZE-2:0],1'b1};
			end
		end
		else if (branch_equality == 0 && is_branch == 1) begin
			if (BHR_dataout_f2 === {BHR_DATA_SIZE{1'bx}}) begin
				BHR_wData = {{{BHR_DATA_SIZE-1}{1'b0}},1'b0};
			end
			else begin
				BHR_wData = {BHR_dataout_f2[BHR_DATA_SIZE-2:0],1'b0};
			end
		end
	end

	assign PHT_address = BHR_dataout ^ pc[6:0];
	assign PHT_waddress = BHR_wData ^ pc_f2;

	//Flop the pc twice
	dff #(.SIZE(PC_SIZE)) PC_f1 (.d(pc),
							.clk(clk),
							.rst(rst),
							.q(pc_f1)
							);
	dff #(.SIZE(PC_SIZE)) PC_f2 (.d(pc_f1),
							.clk(clk),
							.rst(rst),
							.q(pc_f2)
							);

	//Flop the immed val twice
	dff #(.SIZE(ADDR_SIZE)) immedval_fl1 (.d(immedval),
							      .clk(clk),
							      .rst(rst),
							      .q(immedval_f1)
							      );
	dff #(.SIZE(ADDR_SIZE)) immedval_fl2 (.d(immedval_f1),
							      .clk(clk),
							      .rst(rst),
							      .q(immedval_f2)
							      );

	//Flop the BHR data twice
	dff #(.SIZE(BHR_DATA_SIZE)) BHRdata_f1 (.d(BHR_dataout),
							      .clk(clk),
							      .rst(rst),
							      .q(BHR_dataout_f1)
							      );
	dff #(.SIZE(BHR_DATA_SIZE)) BHRdata_f2 (.d(BHR_dataout_f1),
							      .clk(clk),
							      .rst(rst),
							      .q(BHR_dataout_f2)
							      );

	//Flop the PHT data twice
	dff #(.SIZE(PHT_DATA_SIZE)) PHTdata_f1 (.d(PHT_dataout),
							      .clk(clk),
							      .rst(rst),
							      .q(PHT_dataout_f1)
							      );
	dff #(.SIZE(PHT_DATA_SIZE)) PHTdata_f2 (.d(PHT_dataout_f1),
							      .clk(clk),
							      .rst(rst),
							      .q(PHT_dataout_f2)
							      );

	//Instantiate the BHR Table
	dCache #(.BLOCK_SIZE(32),
			 .DATA_SIZE(7),
			 .INDEX_SIZE(7)) BHRTable(.rdAddr(pc),
									  .wrAddr(pc_f2),
									  .wrData(BHR_wData),
									  .rdEn(rdEn),
									  .wrEn(wrEn),
								      .clk(clk),
									  .rst(rst),
									  .data(BHR_dataout),
									  .busy(BHR_busy)
									);

	//Instantiate the PHT
	dCache #(.BLOCK_SIZE(8),
			 .DATA_SIZE(2),
			 .INDEX_SIZE(7)) PHTable(.rdAddr(PHT_address),
									  .wrAddr(PHT_waddress),
									  .wrData(updated_state),
									  .rdEn(rdEn),
									  .wrEn(wrEn),
								      .clk(clk),
									  .rst(rst),
									  .data(PHT_dataout),
									  .busy(PHT_busy)
									);

	//Instantiate the BTB
	dCache #(.BLOCK_SIZE(32),
			 .DATA_SIZE(32),
			 .INDEX_SIZE(7)) BTBuffer(.rdAddr(pc),
									  .wrAddr(pc_f2),
									  .wrData(oldBTBaddress),
									  .rdEn(rdEn),
									  .wrEn(wrEn),
								      .clk(clk),
									  .rst(rst),
									  .data(targetAddr),
									  .busy(BTB_busy),
									  .isHit(isHit)
									);

endmodule: bpredict
