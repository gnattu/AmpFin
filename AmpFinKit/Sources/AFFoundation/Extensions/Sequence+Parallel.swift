import Foundation

// Taken from https://gist.github.com/DougGregor/92a2e4f6e11f6d733fb5065e9d1c880f

public extension Collection {
    func parallelMap<T>(parallelism requestedParallelism: Int? = nil, _ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        let defaultParallelism = 5
        let parallelism = requestedParallelism ?? defaultParallelism
        
        let n = self.count
        if n == 0 {
            return []
        }
        
        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            var result = Array<T?>(repeatElement(nil, count: n))
            
            var i = self.startIndex
            var submitted = 0
            
            func submitNext() async throws {
                if i == self.endIndex { return }
                
                group.addTask { [submitted, i] in
                    let value = try await transform(self[i])
                    return (submitted, value)
                }
                submitted += 1
                formIndex(after: &i)
            }
            
            for _ in 0..<parallelism {
                try await submitNext()
            }
            
            while let (index, taskResult) = try! await group.next() {
                result[index] = taskResult
                
                try Task.checkCancellation()
                try await submitNext()
            }
            
            assert(result.count == n)
            return Array(result.compactMap { $0 })
        }
    }
}
