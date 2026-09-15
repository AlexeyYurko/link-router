import Darwin
import Foundation

runMatchEngineTests()
runProfileDiscoveryTests()
runBrowserLauncherTests()
runNameAndConfigTests()

print("\(checks - failures)/\(checks) checks passed")
if failures > 0 {
    print("\(failures) FAILURES")
    exit(1)
}