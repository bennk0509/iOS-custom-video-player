//
//  BufferQueue.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-03.
//

actor CustomBufferQueue<Element>{
    private var items: [Element] = []
    private var decodeContinuation: CheckedContinuation<Void, Never>?
    private var encodeContinuation: CheckedContinuation<Void, Never>?
    private let yellowThreshold: Int
    private let maxSize: Int
    private var isDecoderAllowedToRun = false
    
    init(yellowThreshold: Int = 400, maxSize: Int = 600) {
        self.yellowThreshold = yellowThreshold
        self.maxSize = maxSize
    }
    
    func enqueue(_ item: Element) async{
        while items.count >= maxSize {
            if Task.isCancelled { return }
            await withTaskCancellationHandler{
                await withCheckedContinuation{continuation in
                    encodeContinuation = continuation
                }
            } onCancel: {
                Task{
                    await wakeEncodeWaiter()
                }
            }
        }
        items.append(item)
        if items.count >= yellowThreshold {
            isDecoderAllowedToRun = true
            decodeContinuation?.resume()
            decodeContinuation = nil
        }
    }
    
    func dequeue() async -> Element? {
        while items.isEmpty || !isDecoderAllowedToRun {
            if Task.isCancelled { return nil }
            if items.isEmpty {
                isDecoderAllowedToRun = false
            }
            await withTaskCancellationHandler{
                await withCheckedContinuation{ continuation in
                    decodeContinuation = continuation
                }
            } onCancel: {
                Task{
                    await wakeDecodeWaiter()
                }
            }
            
        }
        let item = items.removeFirst()
        
        encodeContinuation?.resume()
        encodeContinuation = nil
        return item
    }
    
    func clear() async {
        items.removeAll()
        isDecoderAllowedToRun = false
        wakeDecodeWaiter()
        wakeEncodeWaiter()
    }
    private func wakeDecodeWaiter(){
        decodeContinuation?.resume()
        decodeContinuation = nil
    }
    private func wakeEncodeWaiter(){
        encodeContinuation?.resume()
        encodeContinuation = nil
    }
}
