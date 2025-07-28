`default_nettype none

module spi_peripheral (
    //SPI to PWM Peripheral (asynchronous to system clock)
    input wire      SCLK, // synchronizer clock 
    input wire      COPI, // data out
    input wire      nCs,  // chip select

    // Controllers stuff
    input wire      clk,  // controllers internal clock @10MHz
    input wire      rst_n, // active low reset
    


    //outputs to other parts of the design
    output  reg [7:0] en_reg_out_7_0,
    output  reg [7:0] en_reg_out_15_8,
    output  reg [7:0] en_reg_pwm_7_0,
    output  reg [7:0] en_reg_pwm_15_8,
    output  reg [7:0] pwm_duty_cycle,


);


//initiate registers for synchronization
//d1 -> only looks for input values (nCs, COPI, SCLK) and stores them 
//d0 -> only looks for the value of d1, which is synchronized
reg nCs_sync_d0, nCs_sync_d1;
reg COPI_sync_d0, COPI_sync_d1;
reg SCLK_sync_d0, SCLK_sync_d1;

//initiate wires for edge detection
wire nCS_falling_edge; // active low CS -> falling edge = cue for recieving data
wire SCLK_rising_edge; // cue for reading the synchronized COPI line 

//initiate registers for data extraction 
reg [4:0] message_counter; //count size   
reg [15:0] message; //contains 7 bits for register address and 8 bits for data + 1 Read/Write Bit
// Example Transaction
// Write to 0x00 with 0xF0:
// Bitstream: 1 (Write) + 0000000 (Addr 0x00) + 11110000 (Data 0xF0).

//address validation 
reg message_sent; 

assign nCS_falling_edge = nCS_sync_d1 && !nCS_sync_d0; // Was 1, is now 0
assign SCLK_rising_edge = !SCLK_sync_d1 && SCLK_sync_d0; // Was 0, is now 1

always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin //when reset is triggered (cuz active low)
        // reset for 

        message_counter <= 5'b0;
        message <= 16'b0;
        message_sent <= 1'b0;

        //reset for edge 
        // reset for synchronization
        nCs_sync_d0 <= 1'b1; //by default shouold be 1 (0 is when controller does its Chip Select)
        nCs_sync_d1 <= 1'b1; 
        SCLK_sync_d1 <= 1'b0; //by default, SCLK should be low (SPI Mode 0)
        SCLK_sync_d0 <= 1'b0;

        COPI_sync_d0 <= 1'b0;
        COPI_sync_d1 <= 1'b0;
    end else begin

        // reset status after message sent
        if(message_sent) message_sent <= 1'b0;


        // shift data through synchronizer chain
        nCs_sync_d1 <= nCs;
        nCs_sync_d0 <= nCs_sync_d1

        SCLK_sync_d1 <= SCLK;
        SCLK_sync_d0 <= SCLK_sync_d1;

        COPI_sync_d1 <= COPI;
        COPI_sync_d0 <= COPI_sync_d1;

        //start of message sending process
        if(nCS_falling_edge) begin 
            bit_counter <= 5'b0; //reset bit counter
            message <= 16'b0; //clear previous message
            message_sent <= 1'b0; //no message
        end

        //for an active transaction
        else if (!nCs_sync_d0 && SCLK_rising_edge) begin
            if(bit_counter < 16) begin //since messages have to be less than 16

            //building message left to right, (MSB first)
            message[15-bitcounter] <= COPI_sync_d0;

            bit_counter <= bit_counter + 1;

                if(bit_counter == 5'd15) begin
                    message_sent <= 1'b1;
                end
            end
        end
    end
end




end module