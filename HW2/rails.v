module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output       valid;
output       result; 

integer i;
integer     index_depart;
integer     index_stack;
reg         flag;
reg         valid_flag; 
reg         result_flag;
reg [3:0]   counter;
reg [3:0]   stack [0:9];
reg [3:0]   departure [0:9];

always @(posedge clk or posedge reset) begin
    if (reset || valid) begin
        // Initialize counter and top to 0, and clear stack
        flag <= 1;
        counter <= 0;
        valid_flag <= 0;
        result_flag <= 0;
        index_stack <= -1;
        index_depart <= 0;

    end else begin
        if(data) begin
            if(flag) begin
                // num <= data;
                counter <= data;
                flag <= 0;
                index_stack <= -1;

            end else begin
                index_depart <= index_depart + 1;
                departure[index_depart] <= data;
            end
        end else begin
            if(counter != departure[index_depart]) begin
                if(stack[index_stack-1]==counter) begin
                    stack[index_stack-1] <= 0;
                    index_stack <= index_stack - 1;
                    counter <= counter - 1;
                end else begin
                    index_stack <= index_stack + 1;
                    stack[index_stack] <= departure[index_depart];
                    departure[index_depart] <= 0;
                    index_depart <= index_depart - 1;
                end
            end else if(index_depart>-1) begin
                departure[index_depart] <= 0;
                index_depart <= index_depart - 1;
                counter <= counter - 1;
            end
            
            if(index_depart<0 && index_stack>0) begin
                if(stack[index_stack-1]==counter) begin
                    stack[index_stack-1] <= 0;
                    index_stack <= index_stack - 1;
                    counter <= counter - 1;
                end else begin
                    for (i = 0; i < 10; i = i + 1) begin
                        stack[i] <= 4'h0;
                    end
                    departure[i] <= 4'h0;
                    valid_flag <= 1;
                end
            end else if(index_depart<0 && index_stack==0 && counter==0)begin
                for (i = 0; i < 10; i = i + 1) begin
                    stack[i] <= 4'h0;
                    departure[i] <= 4'h0;
                end
                valid_flag <= 1;
                result_flag <= 1;
            end
        end
    end
end

assign valid = valid_flag;
assign result = result_flag;
endmodule