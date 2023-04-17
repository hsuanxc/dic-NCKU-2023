module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output valid;
output [6:0] result;


//-----Your design-----//
reg valid_flag;
reg [7:0] input_Stack [0:15];
reg [6:0] output_result;
reg [7:0] output_Stack [0:15];
reg [7:0] operator_Stack [0:15];

// Operator precedence table
integer i;
integer flag;
integer input_top;
integer output_top;
integer operator_top;

parameter [5:0] ADD = 6'd43;       // +
parameter [5:0] SUB = 6'd45;       // -
parameter [5:0] MUL = 6'd42;       // *
parameter [5:0] LPAREN = 6'd40;    // (
parameter [5:0] RPAREN = 6'd41;    // (
parameter [5:0] EQL = 6'd61;       // =

always @(posedge clk) begin
    if (rst || valid) begin
        // Reset stack and output string
        flag = 0;
        input_top = -1;
        output_top = -1;
        operator_top = -1;
        valid_flag = 0;
        output_result = 7'bx;
        for (i = 0; i < 16; i = i + 1) begin
            input_Stack[i] = 7'bx;
            output_Stack[i] = 7'bx;
            operator_Stack[i] = 7'bx;
        end
    end else if(flag == 0) begin
        if(ascii_in == EQL) begin
            input_top = input_top + 1;
            input_Stack[input_top] = ascii_in;
            flag = 1;
            i = 0;
        end else begin
            input_top = input_top + 1;
            input_Stack[input_top] = ascii_in;
        end
    end else if(flag == 1) begin
        if(input_Stack[i] != EQL) begin
            if(input_Stack[i]>=48 && input_Stack[i]<=57) begin  //0-9
                output_top = output_top + 1;
                output_Stack[output_top] = input_Stack[i]-48;
                i = i + 1;

            end else if(input_Stack[i]>=97 && input_Stack[i]<=102) begin //10-15
                output_top = output_top + 1;
                output_Stack[output_top] = input_Stack[i]-87;
                i = i + 1;

            end else if(input_Stack[i] == LPAREN) begin
                operator_top = operator_top + 1;
                operator_Stack[operator_top] = input_Stack[i];
                i = i + 1;

            end else if(input_Stack[i] == RPAREN) begin
                if(operator_Stack[operator_top] == LPAREN) begin
                    operator_Stack[operator_top] = 7'bx;
                    i = i + 1;
                end else begin
                    output_top = output_top + 1;
                    output_Stack[output_top] = operator_Stack[operator_top];
                end
                operator_top = operator_top - 1;

            end else begin
                if( ( operator_top!=-1 && rank(operator_Stack[operator_top]) >= rank(input_Stack[i]) ) && operator_Stack[operator_top]!=LPAREN) begin
                    output_top = output_top + 1;
                    output_Stack[output_top] = operator_Stack[operator_top];
                    operator_Stack[operator_top] = 7'bx;
                    operator_top = operator_top - 1;
                end else begin
                    operator_top = operator_top + 1;
                    operator_Stack[operator_top] = input_Stack[i];
                    i = i + 1;
                end
            end
        end else begin
            if(operator_top > -1) begin
                output_top = output_top + 1;
                output_Stack[output_top] = operator_Stack[operator_top];
                operator_top = operator_top - 1;
            end else begin
                flag = 2;
                i = 0;
            end
        end
    end else if(flag == 2) begin
        if(i<=output_top) begin
            if(output_Stack[i] == ADD) begin
                operator_Stack[operator_top-1] = operator_Stack[operator_top-1] + operator_Stack[operator_top];
                operator_Stack[operator_top] = 7'bx;
                operator_top = operator_top - 1;
            end else if(output_Stack[i] == SUB) begin
                operator_Stack[operator_top-1] = operator_Stack[operator_top-1] - operator_Stack[operator_top];
                operator_Stack[operator_top] = 7'bx;
                operator_top = operator_top - 1;
            end else if(output_Stack[i] == MUL)  begin
                operator_Stack[operator_top-1] = operator_Stack[operator_top-1] * operator_Stack[operator_top];
                operator_Stack[operator_top] = 7'bx;
                operator_top = operator_top - 1;
            end else begin
                operator_top = operator_top + 1;
                operator_Stack[operator_top] = output_Stack[i];
            end
            i = i + 1;
        end else begin
            output_top = -1;
            flag = 3;
        end
        
    end else if(flag == 3) begin
        output_result = operator_Stack[0];
        valid_flag = 1;
    end
end

assign valid = valid_flag;
assign result = output_result;

// function ranking
function rank;
input [7:0] x;
    case(x)
        ADD: rank = 0;
        SUB: rank = 0;
        MUL: rank = 1;
        default: rank = 0;
    endcase
endfunction

endmodule