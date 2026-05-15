May/1/2026:
  Getting to know verilog syntax and practice problems on HDLbits https://hdlbits.01xz.net/wiki/Special:VlgStats/60887462D60A7C34
  Just found this really cool circuit called a carry-select adder.
  Suppose in case A we have two 16-bit adders that make up a 32-bit [31:0] adder. In this A scenario, the 16-bit adder that makes up the upper half bits [31:16] of the 32-bit adder has to wait for the carry-out value from the 16-bit [0:15] bottom adder. This means the calculations for the upper 16 bits have to wait until we get the carry out from the lower 16-bit adder.
  Now in case B, we run 3 adders in parallel. The [0:15] bit bottom adder runs per usual, but in parallel we can run two other adders for the upper bits. The adder upper_1 takes in the input 16 bits [31:16], and assumes that the carry-out from the bottom adder = 1. Similarly, upper_0 assumes that the bottom carry-out = 0. Since the upper adders don't have to wait, but instead run on assumptions of the bottom carry-out, all three adders essentially run in parallel. Then, when the actual carry-out value is found, a 2-1 mux chooses the output from upper_1 or upper_0 accordingly. Thus the upper bits [31:16] are selected much faster in the Case B carry-select adder than in the case A ripple-carry adder.
  This dynamic reminds me of CPUs and GPUs, where CPUs take up less die space to run processes in series while GPUs take up more die space to run them in parallel.

May/3/2026:
  Learned about the Sum-of-Products method to create logic for any boolean truth table. The process is intuitive.
  Given a truth table, there will be 2^N permutations of input values (in the table below, there are 8 permutations since we have 3 inputs):
    +---------+---------+---------+-----+
    | input_1 | input_2 | input_3 | out |
    +---------+---------+---------+-----+
    | 0       | 0       | 0       | 0   |
    | 0       | 0       | 1       | 1   |
    | 0       | 1       | 0       | 0   |
    | 0       | 1       | 1       | 0   |
    | 1       | 0       | 0       | 0   |
    | 1       | 0       | 1       | 1   |
    | 1       | 1       | 0       | 0   |
    | 1       | 1       | 1       | 1   |
    +---------+---------+---------+-----+
    
    And now, out = "Sum-of-Products logic"
    The Sum-of-Products method aims to find all cases where out = 1, using only AND & OR logic gates. So: (0,0,1) = 1; (1,0,1) = 1; and (1,1,1) = 1
    - For the case (0,0,1) = 1, we find (~input_1 AND ~input_2 AND input_3) = 1
    This process is repeated for all cases when out = 1, thereby finding all permutations of inputs that can result in out being True.
    - For the case (1,0,1) = 1, we find (input_1 AND ~input_2 AND input_3) = 1
    - For the case (1,1,1) = 1, we find (input_1 AND input_2 AND input_3) = 1
    Finally, when ANY of these desired cases are True, out = 1. Thus out = (~input_1 AND ~input_2 AND input_3) OR (input_1 AND ~input_2 AND input_3) OR (input_1 AND input_2 AND input_3)

  Maybe I can write a python script that performs this method after being given a truth table. The expression given by the Sum-of-Products method can probably be simplified using Karnaugh maps and Boolean algebra.

May/6/2026:
  The last few days have involved lots of practice with flip flops, shift-registers, and iterative methods. Finally, I've started working on actually building the SPI peripheral. Looking through UWASIC Onboarding documentation, the metastability fix caught my eye. Was confused on how the fix worked at first, but this video explains it in simple terms on Youtube: https://www.youtube.com/watch?v=RWh5sKgAuj0. For a deeper understnding, this video was quite helpful: https://www.youtube.com/watch?v=5PRuPVIjEcs.
  Essentially, metastability occurs when a signal is sampled by a flip flop right as it changes value. The flip flop can then go to either 0 or 1, based on environmental factors. However, it takes time to settle to a definite value and can cause errors in code/ASICs.
  So how do we fix it? Metastability can be fixed by decreasing the frequency (increasing the clock period), since this increases the time available for the data to settle. However, practically having many different/slower clock frequencies may not be feasable. The solution proposed in UWASIC documentation: We accept metastibility can occur and instead work around it using a "synchonization chain".
  A synchonization chain works by having two D-flip flops sampling a signal in series. Both Dffs are clocked by the faster clock of the destination domain (in the case of this onboarding project). While the first Dff can still go metastable, that signal isn't used by the destination domain. Instead the metastable output is given time to settle by passing it through the second Dff, thereby exponentially reducing the probability of the metastable signal making it to any useful components of the peripheral. Simple fix for an unavoidable problem!

May/9/2026:
  Learning about edge detection logic as I'm working on the SPI peripheral code. Kinda stuck, but I get the part about non-blocking assignments and how they're used in sequential logic. A non-blocking assignment measures the current value of an 'assigner' signal, and then assigns it to the 'assignee' at the end of the wait period. This wait period allows for other active events and logic on that time step to be evaluated. Typically, the wait period is several orders of magnitude (1,000 to 10,000 times) smaller than the clock cycle so that it doesn't mess up the measurements and assignments at the next clock edge.
  For example, suppose we have registers line_a and line_b, and every positive clockedge we have a simple d-flip-flop assigning line_a to the value of line_b.
  always@(posedge clk) begin
  line_a <= line_b;
  end
  In this circuit, value of line_b is measured immediately, and after a wait period 1000x smaller than the clock cycle, line_a is assigned to the previously measured value of line_b.

May/15/2026
  Make is a pain to install/run on winows. Because Make is intended for Linux, certain commands that Make executes don't even work.
  Not to mention, cocotb doesn't work on recent python versions like 3.14.
  A whole host of issues. But here's what I learned about simulating and testing verilog files:

    After writing some verilog code, it needs to be simulated it to ensure everything is working as planned (since we don't want errors to end up in the real-world ASICs).
    As a crucial precursor step to simulation, a "testbench" (test.py) is written. The testbench is written to provide the simulator with realisic inputs that would be sent into the "device under testing" (in this case, the DUT is the top module of the verilog written beforehand). In each instance of an input, based on the function of the DUT, we expect a certain ouput: Thus, the testbench also checks for the correct corresponding outputs.
    While the simulation can be written in verilog, cocotb makes this much easier by allowing the testbench to be written in python.
    
    The next step is getting Icarus Verilog to create the simulation. While this could be done using terminal commmands, the task is long and arduous. Hence, the easier option is to use automation tools such as Make or Pytest.
      Make could be best descrived as a "build driver". The Makefile gathers information such as the project files, testbench file, simulator (IVerilog), and the toplevel language. It then runs the required terminal commands to pass the information to the IVerilog compiler. Make by itself will not deliver rich test results like Pytest. It will only run the tools you tell it to run and leave you with the output files (like .vvp and .vcd from IVerilog) and standard terminal text.
      Pytest is more of a "test driver". Although it is purely a python testing tool, it can be used to drive verilog testbenches through the help of a bridge library like cocotb. Similarly to Make, a configuration file has to be written detailing the project information (in this project I named it conftest.py). From there, Pytest can be called to terminal, where it will execute the required terminal commands to run the testbench through IVerilog. While both Make and Pytest will automate the testbench commands, Pytest will also 'look' into the simulation and provide its own test results in the terminal.

    When either Make or Pytest are used to drive the simulation, they are provided a simulator in the makefiles/configuration files. For this project Icarus Verilog is used as a simulator. However, there is a caveat here. Icarus Verilog is actually a suite of tools, of which Iverilog is the compiler. IVerilog reads the high-level Verilog code (the DUT, not the testbench yet), parses the modules, wires, and gates, checks for semantic or syntax errors, and translates it into a low-level target format. The ouput provided by the compiler is put into the output.vvp executable.
    Next, Pytest/Make will launch the vvp simulation engine. Here, the simulation engine is made to load cocotb's VPI (Verilog Procedural Interface) shared object library, which converts the Python testbench into code that the vvp can read. Pytest, specifically, connects via Memory Interfaces: It wraps around IVerilog to build the code, then creates a real-time, interactive data pipeline directly into vvp. This pipeline allows Pytest to show test success/failure and detailed error messages in the terminal. The vvp simulator uses output.vvp and the testbench to assert wether or not the DUT is passing or failing, and produces a dump.vcd file for the waveform viewer to process, pass/fail messages, and a results.xml file (specifically for pytest).

    Finally, a waveform viever such as GTKwave can be used to interact with the dump.vcd file and observe the output waveforms of the testbench.

  To summarize, the flow order for my tests is: DUT verilog files + testbench test.py → conftest.py → pytest & cocotb → iverilog (including compilation and vvp simulation) → dump.vcd → GTKWave → View Waveforms
                                                      → results.xml → Pytest pass/fail/error messages
                                                      → exit messages → unread by Pytest
                                                                                                                                
