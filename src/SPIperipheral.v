module SPIperipheral (
    input SCLK, nCS, COPI,
    input clk, rst_n,
    output [15:0]bit_16_send,//process output in top module
    output transaction_validated,
);


//declaring registers
reg [15:0]COPI_sync1, [15:0]COPI_sync2;
reg nCS_sync1, nCS_sync2;
reg SCLK_sync1, SCLK_sync2;
reg transaction_ready = 1'b0;
reg transaction_processed = 1'b0;


// Process SPI protocol in the clk domain, rst_n is low to reset
integer i = 0;
always @(posedge clk or negedge rst_n) begin
    nCS_sync1 <= nCS;
    nCS_sync2 <= nCS_sync1;
    SCLK_sync1 <= SCLK;
    SCLK_sync2 <= SCLK_sync1;
    if (!rst_n) begin
        transaction_ready <= 1'b0;
        COPIsync_1[15:0] <= 16'b0;
        COPIsync_2[15:0] <= 16'b0;
        i <= 0;
        //What if rst_n is hit and resets the COPI_sync registers to zero while data is still being pushed into them?
        //The registers would then be half-filled, which would result in an incorrect address and/or message.
        //This is a non-issue since setting the COPI_sync registers to zero will result in a 'read' first bit, meaning we can ignore the broken message.
    end
    else if ({(nCS_sync2 == 1'b0) & (SCLK_sync2 & !SCLK_sync1)}) begin
            COPIsync_1[15-i] <= COPI;
            COPIsync_2[15-i] <= COPIsync_1[15-i];
            i <= i + 1;
            //bit[15] will be the read/write bit, and if bit[15] == 0, the message will be diregarded by the top module
    end
    else begin
        if (nCS_sync2 & !nCS_sync1) begin //posedge of nCS
            transaction_ready <=  1'b1;
        end
        else if (transaction_processed) begin
            transaction_ready <= 1'b0;
            COPIsync_1[15:0] <= 16'b0;
            COPIsync_2[15:0] <= 16'b0;
            i <= 0;
        end
    end
end

// Update registers only after the complete transaction has finished and been validated
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        transaction_processed <= 1'b1;
        transaction_validated <= 1'b0;
    end 
    else if (transaction_ready && !transaction_processed) begin
        bit_16_send[15:0] <= COPIsync_2[15:0]
        transaction_validated <= 1'b1;
        transaction_processed <= 1'b1;
        end
    else if (!transaction_ready && transaction_processed) begin
        transaction_processed <= 1'b0;
        transaction_validated <= 1'b0;
    end
end

endmodule

//___________________________________________________________________________
//connect output based on address to these wires
  //wire [7:0] en_reg_out_7_0; address 0x00
 //wire [7:0] en_reg_out_15_8; address 0x01
  //wire [7:0] en_reg_pwm_7_0; address 0x02
  //wire [7:0] en_reg_pwm_15_8; address 0x03
  //wire [7:0] pwm_duty_cycle; address 0x04

//This 'assignment' of SCLK, nCS, and COPI will happen in the top module when instantiating SPIperipheral.
//wire SCLK, nCS, COPI;
  //assign SCLK = ui_in[0];
  //assign nCS = ui_in[2];
  //assign COPI = ui_in[1];

  
//Order of operations:

//Get synced signals for SCLK, COPI and nCS
//COPIsync_1[i] <= COPI;
//reg [15:0]COPIsync_1, [15:0]COPIsync_2;
  //  COPIsync_2[i] <= COPIsync_1[i];
    //i = i + 1;

//Know at which cycle of clk the posedge of SCLK happens: SCLK_prev <= SCLK; {~SCLK_prev} & {SCLK} = 1

//build in reset fuctionality: when rst_n goes to zero; i, COPIsync_1, COPIsync_2, = 0; nCS_sync1, nCS_sync2 = 1.

//When to stop Writing to register of COPIsync_2? when i = 15
//When to stop Writing to register COPIsync_1? when nCS_sync2 = 1.

//When the reg COPIsync_2 is filled with 16 bits, Transaction_ready = 1


//Process transaction under separate always loop by:

//Add check for first R/W bit [15] --> if its zero, the command should be ignored

//build in reset fuctionality: when rst_n goes to zero; transaction_validated = 0, transaction_processed = 1

//Send data COPI_sync2 to bit_16_send output
//_________________________________________________________________________________