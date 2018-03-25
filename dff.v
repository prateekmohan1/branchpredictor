module dff 
	#(parameter SIZE=32)
	(
	input logic [SIZE-1:0] d,
	input logic clk,
	input logic rst,
	output logic [SIZE-1:0] q
	);
	
	always_ff @(posedge clk) begin
		if (~rst) begin
			q <= {SIZE{1'd0}};
		end
		else begin
			q <= d;
		end
	end

endmodule: dff
