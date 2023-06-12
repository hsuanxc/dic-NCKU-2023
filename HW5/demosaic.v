module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;

output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;

output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;

output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output reg done;

//-----------------------------------------------//
//--------------------Hsuan----------------------//
//-----------------------------------------------//

reg div;
reg [2:0] state, nextState;
reg [3:0] ref;
reg [10:0] sum;
reg [13:0] counter;

localparam INIT = 3'd0;
localparam GREEN_PAD = 3'd1;
localparam RED_PAD = 3'd2;
localparam BLUE_PAD = 3'd3;
localparam FINISH = 3'd4;

always @(posedge clk) begin
    if(reset) state <= INIT;
    else state <= nextState;
end

always @(posedge clk) begin
    case(state)
        INIT: begin
            if(reset) begin
                counter <= 0;
                addr_r <= 0;
                addr_g <= 0;
                addr_b <= 0;
                ref <= 0;
                div <= 0;
                sum <= 0;
                done <= 0;
            end 
            else begin
                counter <= counter + 14'b1;
                if(counter[7]==counter[0]) begin // save in green
                    wr_r <= 0;
                    wr_g <= 1;
                    wr_b <= 0;
                    addr_g <= counter;
                    wdata_g <= data_in;
                end
                else if(counter[7]==0 && counter[0]==1) begin // save in red
                    wr_r <= 1;
                    wr_g <= 0;
                    wr_b <= 0;
                    addr_r <= counter;
                    wdata_r <= data_in;
                end
                else if(counter[7]==1 && counter[0]==0) begin // save in blue
                    wr_r <= 0;
                    wr_g <= 0;
                    wr_b <= 1;
                    addr_b <= counter;
                    wdata_b <= data_in;
                end
                if(counter == 16383) begin
                    wr_r <= 0;
                    wr_g <= 0;
                    wr_b <= 0;
                    counter <= 0;
                end
            end
        end
    //GREEN
        GREEN_PAD: begin
            if( counter[7] ^ counter[0] ) begin
                case(ref)
                    0: begin //up
                        addr_g <= {counter[13:7]-7'd1, counter[6:0]};
                    end
                    1: begin //down
                        addr_g <= {counter[13:7]+7'd1, counter[6:0]};
                        sum <= sum + rdata_g;
                    end
                    2: begin //left
                        addr_g <= {counter[13:7], counter[6:0]-7'd1};
                        sum <= sum + rdata_g;
                    end
                    3: begin //right
                        addr_g <=  {counter[13:7], counter[6:0]+7'd1};
                        sum <= sum + rdata_g;
                    end
                endcase
                ref <= ref + 4'd1;
            end
            else begin
                counter <= counter + 1;
            end

            if(ref == 4'd4) begin
                ref <= 0;
                counter <= counter + 1;
                sum <= 0;
                wr_g <= 1;
                addr_g <= counter;
                wdata_g <= (sum + rdata_g) >> 2;
            end
            else begin
                wr_g <= 0;
            end

            if(counter == 16383) begin
                counter <= 0;
                wr_g <= 0;
                addr_g <= 0;
            end
        end
    // RED
        RED_PAD: begin
            if( counter[7]==0 && counter[0]==0 ) begin   // left-right
                case(ref)
                    0: begin //left
                        addr_r <= {counter[13:7], counter[6:0]-7'd1};
                    end
                    2: begin //right
                        addr_r <= {counter[13:7],  counter[6:0]+7'd1};
                        sum <= sum + rdata_r;
                    end
                endcase
                div <= 0;
                ref <= ref + 4'd2;
            end
            else if(counter[7]==1 && counter[0]==1) begin  // up-down
                case(ref)
                    0: begin //up
                        addr_r <= {counter[13:7]-7'd1, counter[6:0]};
                    end
                    2: begin //down
                        addr_r <= {counter[13:7]+7'd1, counter[6:0]};
                        sum <= sum + rdata_r;
                    end
                endcase
                div <= 0;
                ref <= ref + 4'd2;
            end
            else if(counter[7]==1 && counter[0]==0) begin // four-corner
                case(ref)
                    0: begin //up-left
                        addr_r <= {counter[13:7]-7'd1, counter[6:0]-7'd1};
                    end
                    1: begin //up-right
                        addr_r <= {counter[13:7]-7'd1, counter[6:0]+7'd1};
                        sum <= sum + rdata_r;
                    end
                    2: begin //down-left
                        addr_r <= {counter[13:7]+7'd1, counter[6:0]-7'd1};
                        sum <= sum + rdata_r;
                    end
                    3: begin //down-right
                        addr_r <=  {counter[13:7]+7'd1, counter[6:0]+7'd1};
                        sum <= sum + rdata_r;
                    end
                endcase
                div <= 1;
                ref <= ref + 4'd1;
            end
            else begin
                counter <= counter + 1;
            end

            if(ref == 4'd4) begin
                ref <= 0;
                counter <= counter + 1;
                sum <= 0;
                wr_r <= 1;
                addr_r <= counter;
                if(div) wdata_r <= (sum + rdata_r) >> 2;
                else wdata_r <= (sum + rdata_r) >> 1;
            end
            else begin
                wr_r <= 0;
            end

            if(counter == 16383) begin
                counter <= 0;
                wr_r <= 0;
                addr_r <= 0;
            end
        end
    // BLUE
        BLUE_PAD: begin
            if( counter[7]==1 && counter[0]==1 ) begin  // left-right
                case(ref)
                    0: begin //left
                        addr_b <= {counter[13:7], counter[6:0]-7'd1};
                    end
                    2: begin //right
                        addr_b <= {counter[13:7], counter[6:0]+7'd1};
                        sum <= sum + rdata_b;
                    end
                endcase
                div <= 0;
                ref <= ref + 4'd2;
            end
            else if(counter[7]==0 && counter[0]==0) begin // up-down
                case(ref)
                    0: begin //up
                        addr_b <= {counter[13:7]-7'd1, counter[6:0]};
                    end
                    2: begin //down
                        addr_b <= {counter[13:7]+7'd1, counter[6:0]};
                        sum <= sum + rdata_b;
                    end
                endcase
                div <= 0;
                ref <= ref + 4'd2;
            end
            else if(counter[7]==0 && counter[0]==1) begin // four-corner
                case(ref)
                    0: begin //up-left
                        addr_b <= {counter[13:7]-7'd1, counter[6:0]-7'd1};
                    end
                    1: begin //up-right
                        addr_b <= {counter[13:7]-7'd1, counter[6:0]+7'd1};
                        sum <= sum + rdata_b;
                    end
                    2: begin //down-left
                        addr_b <= {counter[13:7]+7'd1, counter[6:0]-7'd1};
                        sum <= sum + rdata_b;
                    end
                    3: begin //down-right
                        addr_b <=  {counter[13:7]+7'd1, counter[6:0]+7'd1};
                        sum <= sum + rdata_b;
                    end
                endcase
                div <= 1;
                ref <= ref + 4'd1;
            end
            else begin
                counter <= counter + 1;
            end

            if(ref == 4'd4) begin
                ref <= 0;
                counter <= counter + 1;
                sum <= 0;
                wr_b <= 1;
                addr_b <= counter;
                if(div) wdata_b <= (sum + rdata_b) >> 2;
                else wdata_b <= (sum + rdata_b) >> 1;
            end
            else begin
                wr_b <= 0;
            end
            if(counter == 16383) begin
                counter <= 0;
                wr_b <= 0;
                addr_b <= 0;
            end
        end

        FINISH: begin
            done <= 1;
        end
    endcase
end

always@(*) begin
    case(state)
        INIT: begin
            nextState = (counter==16383)? GREEN_PAD : INIT;
        end
        GREEN_PAD: begin
            nextState = (counter==16383)? RED_PAD : GREEN_PAD;
        end
        RED_PAD: begin
            nextState = (counter==16383)? BLUE_PAD : RED_PAD;
        end
        BLUE_PAD: begin
            nextState = (counter==16383)? FINISH : BLUE_PAD;
        end
        default: nextState = INIT;
    endcase
end

endmodule