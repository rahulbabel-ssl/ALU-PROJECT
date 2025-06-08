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
