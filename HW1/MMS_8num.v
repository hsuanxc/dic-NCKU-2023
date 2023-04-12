
module MMS_8num(result, select, number0, number1, number2, number3, number4, number5, number6, number7);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
input  [7:0] number4;
input  [7:0] number5;
input  [7:0] number6;
input  [7:0] number7;
output [7:0] result; 

wire [1:0] mux;
reg [7:0] result_temp;
wire [7:0] part1, part2;

MMS_4num MMS_mux1(part1, select, number0, number1, number2, number3);
MMS_4num MMS_mux2(part2, select, number4, number5, number6, number7);
assign mux[1] = select;
assign mux[0] = (part1 < part2);

always @* begin
    // First stage of selection using two 4-input MMS modules
    case (mux)
        2'b00 : result_temp = part1;
        2'b01 : result_temp = part2;
        2'b10 : result_temp = part2;
        2'b11 : result_temp = part1;
    endcase
end

// Second stage of selection to determine the final result
assign result = result_temp;

endmodule