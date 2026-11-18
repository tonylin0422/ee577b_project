# NC-Sim may exit successfully after a Verilog $finish on an error.
{ print }
index($0, "TEST FAILED") { failed = 1 }
/^TEST PASSED:|^NIC TEST PASSED[[:space:]]*$/ { passed = 1 }
END { if (failed || !passed) exit 1 }
