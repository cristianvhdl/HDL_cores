`timescale 1ns / 1ps

module MT45W8MW16BGX_module(
//user IO
    input clk,
    input read,
    input write,
    input reset,
    input [23:0] address,
    input [15:0] data_in,
    output [15:0] data_out,
    output reg read_data = 0,

//RAM IO
    output reg RamCLK = 0,
    output reg RamADVn = 0,
    output reg RamCEn = 1,
    output reg RamCRE = 0,
    output reg RamOEn = 1,
    output reg RamWEn = 1,
    output reg RamLBn = 0,
    output reg RamUBn = 0,
    input RamWait,
    inout [15:0] MemDB,
    output [22:0] MemAdr
    );

   //wire [15:0] <output_signal>, <input_signal>;
  // wire        <output_enable_signal>;
   
   //assign <top_level_port> = <output_enable_signal> ? <output_signal> : 16'hzzzz;
  
   //assign <input_signal> = <top_level_port>;
   
assign MemDB = ((state == WRITE0_ST) || (state == WRITE1_ST)) ? data_in : 16'hzzzz;
   
assign data_out = MemDB;

assign MemAdr = address;

//assign MemDB = ((state == WRITE0_ST) || (state == WRITE1_ST)) ? /*input_reg*/ 16'h5555 : 16'hzzzz;
      
//FSM - RAM signal state machine
parameter REST_ST    = 3'b000;
parameter READ0_ST   = 3'b001;
parameter READ1_ST   = 3'b010;
parameter WRITE0_ST  = 3'b011;
parameter WRITE1_ST  = 3'b100;
    
reg [2:0] state = REST_ST;
    
always @ (posedge clk)
    if(reset == 1)
        state = REST_ST;

    else begin
        case (state)
            REST_ST : begin
                RamCEn <= 1;
                RamOEn <= 1;
                RamWEn <= 1;
                read_data <= 0;
                if(read == 1)
                    state <= READ0_ST;
                else if(write == 1)
                    state <= WRITE0_ST;
                else
                    state <= REST_ST;
            end
            
            READ0_ST : begin
                RamCEn <= 0;
                RamOEn <= 0;
                RamWEn <= 1;
                read_data <= 0;
                if(delay_done == 1)
                    state <= READ1_ST;
                else
                    state <= READ0_ST;
            end
                      
            READ1_ST : begin
                RamCEn <= 0;
                RamOEn <= 0;
                RamWEn <= 1;
                read_data <= 1;
                state <= REST_ST;
            end
            
            WRITE0_ST : begin
                RamCEn <= 0;
                RamOEn <= 1;
                RamWEn <= 0;
                if(delay_done == 1)
                    state <= WRITE1_ST;
                else
                    state <= WRITE0_ST;
            end
                                    
            WRITE1_ST : begin
                RamCEn <= 0;
                RamOEn <= 1;
                RamWEn <= 0;
                state <= REST_ST;
            end
        endcase
    end

//delay system
integer counter = 0;
integer counter_max = 10;

reg delay_done = 0;

always @(posedge clk)
    if((state == REST_ST) || (state == READ1_ST) || (state == WRITE1_ST))begin
        counter <= 0;
        delay_done <= 0;
    end
    
    else if(counter < counter_max) begin
        counter <= counter + 1;
        delay_done <= 0;
    end
    
    else begin
        counter <= 0;
        delay_done <= 1;
    end
        
 
    
endmodule
