module alu_design #(parameter N = 8)
(
  input clk, rst,
  input [1:0] inp_valid,
  input mode,
  input [3:0] cmd,
  input ce, cin,
  input [N-1:0] opa, opb,
  output reg err, oflow, cout, g, l, e,
  output reg [(2*N-1):0] res
);

  reg signed [N-1:0] signed_a, signed_b;
  reg signed [N:0] signed_res;

  localparam rotate_N = $clog2(N);
  reg [rotate_N-1:0] rotate_amt;
  reg invalid_rotate;

  reg [(2*N-1):0] res_t;
  reg err_t, oflow_t, cout_t, g_t, l_t, e_t;

  reg [N-1:0] opa_reg, opb_reg;
  reg mode_reg, ce_reg, cin_reg;
  reg [1:0] inp_valid_reg;
  reg [3:0] cmd_reg;

  reg [(2*N-1):0] temp1, temp2;

  parameter add       = 4'b0000;
  parameter sub       = 4'b0001;
  parameter add_cin   = 4'b0010;
  parameter sub_cin   = 4'b0011;
  parameter inc_a     = 4'b0100;
  parameter dec_a     = 4'b0101;
  parameter inc_b     = 4'b0110;
  parameter dec_b     = 4'b0111;
  parameter cmp       = 4'b1000;
  parameter mult      = 4'b1001;
  parameter mult1     = 4'b1010;
  parameter signed_add = 4'b1011;
  parameter signed_sub = 4'b1100;

  parameter and1      = 4'b0000;
  parameter nand1     = 4'b0001;
  parameter or1       = 4'b0010;
  parameter nor1      = 4'b0011;
  parameter xor1      = 4'b0100;
  parameter xnor1     = 4'b0101;
  parameter not_a     = 4'b0110;
  parameter not_b     = 4'b0111;
  parameter shr1_a    = 4'b1000;
  parameter shr1_b    = 4'b1010;
  parameter shl1_a    = 4'b1001;
  parameter shl1_b    = 4'b1011;
  parameter rol_a_b   = 4'b1100;
  parameter ror_a_b   = 4'b1101;

  always @(posedge clk) begin
    if (rst) begin
      opa_reg       <= 0;
      opb_reg       <= 0;
      cmd_reg       <= 0;
      mode_reg      <= 0;
      ce_reg        <= 0;
      cin_reg       <= 0;
      inp_valid_reg <= 0;
    end
    else begin
      opa_reg <= opa;
      opb_reg <= opb;
      cmd_reg <= cmd;
      mode_reg <= mode;
      ce_reg <= ce;
      cin_reg <= cin;
      inp_valid_reg <= inp_valid;
    end
  end

  always @(*) begin
    res_t = 0;
    err_t = 0;
    oflow_t = 0;
    cout_t = 0;
    g_t = 0;
    l_t = 0;
    e_t = 0;



    if (ce_reg) begin
    res_t = 0;
    err_t = 0;
    oflow_t = 0;
    cout_t = 0;
    g_t = 0;
    l_t = 0;
    e_t = 0;
      if (mode_reg) begin
        case (cmd_reg)
          add: if (inp_valid_reg == 2'b11) begin
            res_t = opa_reg + opb_reg;
            cout_t = res_t[N];
          end

          sub: if (inp_valid_reg == 2'b11) begin
            res_t = opa_reg - opb_reg;
            oflow_t = (opa_reg < opb_reg);
          end

          add_cin: if (inp_valid_reg == 2'b11) begin
            res_t = opa_reg + opb_reg + cin_reg;
            cout_t = res_t[N];
          end

          sub_cin: if (inp_valid_reg == 2'b11) begin
            res_t = opa_reg - opb_reg -  cin_reg;
            oflow_t = res_t[N];
          end

          inc_a: if (inp_valid_reg == 2'b11 || inp_valid == 2'b01) begin
             cout_t = (opa_reg == 255)?1:0;
             res_t = opa_reg + 1;
          end

          dec_a: if (inp_valid_reg == 2'b11 || inp_valid == 2'b01) begin
            oflow_t = (opa_reg == 0)?1:0;
            res_t = opa_reg - 1;
          end

          inc_b: if (inp_valid_reg == 2'b11 || inp_valid == 2'b10) begin
            cout_t = (opb_reg == 255)?1:0;
            res_t = opb_reg + 1;
          end

          dec_b: if (inp_valid_reg == 2'b11 || inp_valid == 2'b10) begin
            oflow_t = (opb_reg == 0)?1:0;
            res_t = opb_reg - 1;
          end

          cmp: if (inp_valid_reg == 2'b11) begin
            g_t = (opa_reg > opb_reg);
            l_t = (opa_reg < opb_reg);
            e_t = (opa_reg == opb_reg);
          end

          mult: if (inp_valid_reg == 2'b11) begin
            res_t = (opa_reg + 1) * (opb_reg + 1);
          end

          mult1: if (inp_valid_reg == 2'b11) begin
            res_t = (opa_reg << 1) * opb_reg;
          end

          signed_add: if (inp_valid_reg == 2'b11) begin
            signed_a = $signed(opa_reg);
            signed_b = $signed(opb_reg);
            signed_res = signed_a + signed_b;
            res_t = signed_res;
            oflow_t = (signed_a[N-1] == signed_b[N-1]) && (signed_res[N-1] != signed_a[N-1]);
            g_t = (signed_a > signed_b);
            l_t = (signed_a < signed_b);
            e_t = (signed_a == signed_b);
          end

          signed_sub: if (inp_valid_reg == 2'b11) begin
            signed_a = $signed(opa_reg);
            signed_b = $signed(opb_reg);
            signed_res = signed_a - signed_b;
            res_t = signed_res;
            oflow_t = (signed_a[N-1]== signed_b[N-1]) && (signed_res[N-1] != signed_a[N-1]);
            g_t = (signed_a > signed_b);
            l_t = (signed_a < signed_b);
            e_t = (signed_a == signed_b);
          end

        endcase
      end else begin
        case (cmd_reg)
          and1: if (inp_valid_reg == 2'b11)
                res_t = {{N{1'b0}},opa_reg & opb_reg};

          nand1: if (inp_valid_reg == 2'b11)
                 res_t = {{N{1'b0}},~(opa_reg & opb_reg)};

          or1: if (inp_valid_reg == 2'b11)
               res_t ={{N{1'b0}}, opa_reg | opb_reg};

          nor1: if (inp_valid_reg == 2'b11)
                res_t ={{N{1'b0}},~(opa_reg | opb_reg)};

          xor1: if (inp_valid_reg == 2'b11)
                res_t ={{N{1'b0}}, opa_reg ^ opb_reg};

          xnor1: if (inp_valid_reg == 2'b11)
                 res_t ={{N{1'b0}}, ~(opa_reg ^ opb_reg)};

          not_a: if (inp_valid_reg == 2'b11 || inp_valid == 2'b01)
                 res_t ={{N{1'b0}}, ~opa_reg};

          not_b: if (inp_valid_reg == 2'b11 || inp_valid == 2'b10)
                 res_t ={{N{1'b0}}, ~opb_reg};

          shr1_a: if (inp_valid_reg == 2'b11 || inp_valid == 2'b01)
                  res_t = {{N{1'b0}},opa_reg >> 1};

          shr1_b: if (inp_valid_reg == 2'b11 || inp_valid == 2'b10)
                  res_t = {{N{1'b0}},opb_reg >> 1};

          shl1_a: if (inp_valid_reg == 2'b11 || inp_valid == 2'b01)
                  res_t = {{N{1'b0}},opa_reg << 1};

          shl1_b: if (inp_valid_reg == 2'b11 || inp_valid == 2'b10)
                  res_t = {{N{1'b0}},opb_reg << 1};

          rol_a_b: if (inp_valid_reg == 2'b11) begin
                   rotate_amt = opb_reg[rotate_N-1:0];
                   if (|opb_reg[N-1:rotate_N])begin
                     err_t = 1'b1;
                    res_t = ((opa_reg << rotate_amt) | (opa_reg >> (N - rotate_amt))) & {(N){1'b1}};
                    end
                   else if (rotate_amt == 0)
                     res_t = opa_reg;
                   else
                     res_t = ((opa_reg << rotate_amt) | (opa_reg >> (N - rotate_amt))) & {(N){1'b1}};
                   end

         ror_a_b: if (inp_valid_reg == 2'b11) begin
                  rotate_amt = opb_reg[rotate_N-1:0];
                  if (|opb_reg[N-1:rotate_N])begin
                    err_t = 1'b1;
                    res_t = ((opa_reg >> rotate_amt) | (opa_reg << (N - rotate_amt))) & {(N){1'b1}};
        end
                  else if (rotate_amt == 0)
                    res_t = opa_reg;
                  else
                    res_t = ((opa_reg >> rotate_amt) | (opa_reg << (N - rotate_amt))) & {(N){1'b1}};
                  end
        endcase
      end
    end
  end



  always @(posedge clk) begin
    if (rst) begin
      res <= 0;
      err <= 0;
      oflow <= 0;
      cout <= 0;
      g <= 0;
      l <= 0;
      e <= 0;
      temp1 <= 0;
      temp2 <= 0;
      res_t<=0;
    end else begin
     if ((cmd_reg == mult || cmd_reg == mult1) && mode_reg && ce_reg) begin

        temp2 <= res_t ;
        res <= temp2;
      end else begin
        res <= res_t;
      end



      err <= err_t;
      oflow <= oflow_t;
      cout <= cout_t;
      g <= g_t;
      l <= l_t;
      e <= e_t;
    end
  end

endmodule

[rahulbabel@feserver alu_project]$
[rahulbabel@feserver alu_project]$
[rahulbabel@feserver alu_project]$ cat desig
design_testbench_1.v  design_testbench.v    design.v
[rahulbabel@feserver alu_project]$ cat design_testbench.v
`include "design.v"

`define PASS 1'b1
`define FAIL 1'b0
`define no_of_testcase 153

// Test bench for ALU design
module test_bench_alu();
        reg [55:0] curr_test_case = 56'b0;
        reg [55:0] stimulus_mem [0:`no_of_testcase-1];
        reg [77:0] response_packet;

//Decl for giving the Stimulus
        integer i,j;
        reg CLK,RST,CE; //inputs
        event fetch_stimulus;
        reg [7:0]OPA,OPB; //inputs
        reg [3:0]CMD; //inputs
        reg MODE,CIN; //inputs
        reg [7:0] Feature_ID;
        reg [2:0] Comparison_EGL;  //expected output
        reg [15:0] Expected_RES; //expected output data
        reg err,cout,ov;
        reg [1:0]INP_VALID;

//Decl to Cop UP the DUT OPERATION
        wire  [15:0] RES;
        wire ERR,OFLOW,COUT;
        wire [2:0]EGL;
        wire [21:0] expected_data;
        reg [21:0]exact_data;

//READ DATA FROM THE TEXT VECTOR FILE
        task read_stimulus();
                begin
                #10 $readmemb ("stimulus.txt",stimulus_mem);
               end
        endtask

   alu_design inst_dut (.opa(OPA),.opb(OPB),.cin(CIN),.clk(CLK),.cmd(CMD),.ce(CE),.mode(MODE),.cout(COUT),.oflow(OFLOW),.res(RES),.g(EGL[1]),.e(EGL[2]),.l(EGL[0]),.err(ERR),.rst(RST),.inp_valid(INP_VALID));

//STIMULUS GENERATOR

integer stim_mem_ptr = 0,stim_stimulus_mem_ptr = 0,fid =0 , pointer =0 ;

        always@(fetch_stimulus)
                begin
                        curr_test_case=stimulus_mem[stim_mem_ptr];
                        $display ("stimulus_mem data = %0b \n",stimulus_mem[stim_mem_ptr]);
                        $display ("packet data = %0b \n",curr_test_case);
                        stim_mem_ptr=stim_mem_ptr+1;
                end

//INITIALIZING CLOCK
        initial
                begin CLK=0;
                        forever #60 CLK=~CLK;
                end

//DRIVER MODULE
        task driver ();
                begin
                  ->fetch_stimulus;
                  @(posedge CLK);
                  Feature_ID    =curr_test_case[55:48];
                  RST           =curr_test_case[47];
                  INP_VALID     =curr_test_case[46:45];
                  OPA           =curr_test_case[44:37];
                  OPB           =curr_test_case[36:29];
                  CMD           =curr_test_case[28:25];
                  CIN           =curr_test_case[24];
                  CE            = curr_test_case[23];
                  MODE          =curr_test_case[22];
                  Expected_RES  =curr_test_case[21:6];
                  cout          =curr_test_case[5];
                  Comparison_EGL=curr_test_case[4:2];
                  ov            =curr_test_case[1];
                  err           =curr_test_case[0];
                 $display("At time (%0t), Feature_ID = %d, Inp_val = %2b, OPA = %8b, OPB = %8b, CMD = %4b, CIN = %1b, CE = %1b, MODE = %1b, expected_result = %9b, cout = %1b, Comparison_EGL = %3b, ov = %1b, err = %1b",$time,Feature_ID,INP_VALID,OPA,OPB,CMD,CIN,CE,MODE, Expected_RES,cout,Comparison_EGL,ov,err);
                end
        endtask

//GLOBAL DUT RESET
        task dut_reset ();
                begin
                CE=1;
                #10 RST=1;
                #20 RST=0;
                end
        endtask

//GLOBAL INITIALIZATION
        task global_init ();
                begin
                curr_test_case=56'b0;
                response_packet=78'b0;
                stim_mem_ptr=0;
                end
        endtask


//MONITOR PROGRAM


task monitor ();
                begin
                repeat(2)@(posedge CLK);
                        #5 response_packet[55:0]=curr_test_case;
                response_packet[56]     =ERR;
                        response_packet[57]     =OFLOW;
                        response_packet[60:58]  ={EGL};
                        response_packet[61]     =COUT;
                        response_packet[77:62]  =RES;
               // response_packet[63]   =0; // Reserved Bit
                $display("Monitor: At time (%0t), RES = %16b, COUT = %1b, EGL = %3b, OFLOW = %1b, ERR = %1b",$time,RES,COUT,{EGL},OFLOW,ERR);
                exact_data ={RES,COUT,{EGL},OFLOW,ERR};
                end
        endtask

assign expected_data = {Expected_RES,cout,Comparison_EGL,ov,err};

//SCORE BOARD PROGRAM TO CHECK THE DUT OP WITH EXPECTD OP

   reg [54:0] scb_stimulus_mem [0:`no_of_testcase-1];

task score_board();
   reg [21:0] expected_res;
   reg [7:0] feature_id;
   reg [21:0] response_data;
                begin
                #5;
                feature_id = curr_test_case[55:48];
                expected_res = curr_test_case[21:6];
                response_data = response_packet[77:56];
                $display("expected result = %22b ,response data = %22b",expected_data,exact_data);
                 if(expected_data === exact_data)
                     scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`PASS};
                 else
                     scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`FAIL};
            stim_stimulus_mem_ptr = stim_stimulus_mem_ptr + 1;
        end
endtask


//Generating the report `no_of_testcase-1
task gen_report;
integer file_id,pointer;
reg [54:0] status;
                begin
                   file_id = $fopen("results.txt", "w");
                   for(pointer = 0; pointer <= `no_of_testcase-1 ; pointer = pointer+1 )
                   begin
                     status = scb_stimulus_mem[pointer];
                     if(status[0])
                       $fdisplay(file_id, "Feature ID %d : PASS", status[53:46]);
                     else
                       $fdisplay(file_id, "Feature ID %d : FAIL", status[53:46]);
                   end
                end
endtask


initial
               begin
                #10;
                global_init();
                dut_reset();
                read_stimulus();
                for(j=0;j<=`no_of_testcase-1;j=j+1)
                begin
                       // fork
                          driver();
                        @(posedge CLK);
                          monitor();

                         //join
                        score_board();
               end

               gen_report();
               $fclose(fid);
               #300 $finish();
               end
endmodule
