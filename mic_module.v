`timescale 1ns / 1ps

module mic_module(
    input clk,
    input reset,

//SPI interface  
    input miso,
    output wire spi_clk,
    output reg chip_select = 1,
    
//FPGA interface  
    input en,  
    output [11:0] data,
    output reg read_data = 0
    );
    
reg clk_en = 0;
    
    
//clock divider

integer counter = 0;
integer counter_max = 5;

reg internal_clk = 1;

always @(posedge clk)
    if((counter < counter_max) & (clk_en == 1)) begin
        counter <= counter + 1;
    end
    
    else if(clk_en == 0) begin 
        counter <= 0;
        internal_clk <= 1;
    end
    
    else begin
        counter <= 0;
        internal_clk = ~internal_clk;
    end
 
assign spi_clk = internal_clk;    

//FSM
parameter REST_ST   = 2'b00;
parameter SHIFT0_ST = 2'b01;
parameter SHIFT1_ST = 2'b10;
parameter DONE_ST   = 2'b11;

reg [1:0] state = REST_ST;

always @ (posedge clk)
    if(reset == 1)
        state = REST_ST;

    else begin
        case (state)
            REST_ST : begin
                chip_select <= 1;
                clk_en <= 0;
                read_data <= 0;
                
                if(en == 1) begin
                    state <= SHIFT0_ST;
                    clk_en <= 1;
                end
                
                else begin
                    state <= REST_ST;
                    clk_en <= 0;
                end
            end
            
            SHIFT0_ST : begin
                chip_select <= 0;
                clk_en <= 1;
                read_data <= 0;
                if(internal_data[15] == 1)
                    state <= SHIFT1_ST;
                else
                    state <= SHIFT0_ST;
            end
            
            SHIFT1_ST : begin
                chip_select <= 0;
                clk_en <= 1;
                read_data <= 0;
                if(internal_data[15] == 0)
                    state <= DONE_ST;
                else
                    state <= SHIFT1_ST;
            end
            
            DONE_ST : begin
                chip_select <= 1;
                clk_en <= 0;
                read_data <= 1;
                state <= REST_ST;
            end    
        endcase
    end
    

//shift register
reg [15:0] internal_data = 16'b1111111111111110;

always @ (negedge internal_clk)
    if((reset == 1) || (internal_data[15] == 0))
        internal_data <= 16'b1111111111111110;
    else
        internal_data <= {internal_data[14:0], miso};
  
assign data = internal_data[11:0];

endmodule
