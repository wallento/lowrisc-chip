@Library('librecoresci') import org.librecores.ci.Modules
def lcci = new Modules(steps)

node('fpga-nexys4ddr') {
  lcci.load(["eda/xilinx/vivado/2016.4",
             "eda/verilator/3.902"])

  stage("Checkout") {
    checkout scm
  }
}
