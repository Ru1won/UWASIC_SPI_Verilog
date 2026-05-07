module SPIperipheral (
    input SCLK, nCS, COPI;
    input clk, rst_n;
    output //send to register address and 8-bit data to register
);

//connect output based on address to these wires
  wire [7:0] en_reg_out_7_0;
  wire [7:0] en_reg_out_15_8;
  wire [7:0] en_reg_pwm_7_0;
  wire [7:0] en_reg_pwm_15_8;
  wire [7:0] pwm_duty_cycle;

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

//build in reset fuctionality: when rst_n goes to zero; transaction_ready = 0, transaction processed = 0

//Send data [7:0] to address in bits [14:8], transaction processed = 1

//if transaction ready & transaction processed = 1, then reset transaction ready to 0 and reset reg COPIsync_1, COPIsync_2, = 0
    
    
  end
 end
//_________________________________________________________________________________
// Process SPI protocol in the clk domain, rst_n is low to reset

reg [15:0]COPI_sync1, [15:0]COPI_sync2;
reg nCS_sync1, nCS_sync2;
reg SCLK_sync1, SCLK_sync2;

always@(posedge clk or negedge rst_n) begin

integer i = 0;
always @(posedge clk or negedge rst_n) begin
    SCLK_prev <= SCLK;
    if (nCS) begin
        i = 0
    end
    else if ({~SCLK_prev & SCLK}) begin
    COPIsync_1[i] <= COPI;
    COPIsync_2[i] <= COPIsync_1[i];
    i = i + 1;
    end
    else if 
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // omitted code
        transaction_ready <= 1'b0;
        // omitted code
    end else if (nCS_sync2 == 1'b0) begin
        // omitted code
    end else begin
        // When nCS goes high (transaction ends), validate the complete transaction
        if (nCS_posedge) begin
            transaction_ready <= 1'b1;
        end else if (transaction_processed) begin
            // Clear ready flag once processed
            transaction_ready <= 1'b0;
        end
        // omitted code
    end
end

// Update registers only after the complete transaction has finished and been validated
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // omitted code
        transaction_processed <= 1'b0;
    end else if (transaction_ready && !transaction_processed) begin
        // Transaction is ready and not yet processed
        // omitted code
        // Set the processed flag
        transaction_processed <= 1'b1;
    end else if (!transaction_ready && transaction_processed) begin
        // Reset processed flag when ready flag is cleared
        transaction_processed <= 1'b0;
    end
end

endmodule