import Darwin
import Foundation

extension AppViewModel {
    func formattedMemoryUsageMB() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return "—" }
        let megabytes = Double(info.resident_size) / (1024 * 1024)
        return String(format: "%.0f MB", megabytes)
    }
}
