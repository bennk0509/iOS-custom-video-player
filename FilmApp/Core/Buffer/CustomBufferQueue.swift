//
//  BufferQueue.swift
//  FilmApp
//
//  Created by Ben Nguyen on 2026-09-03.
//

actor CustomBufferQueue<Element>{
    private var items: [Element] = []
    private var decodeContinuation: CheckedContinuation<Void, Never>?
    private var renderContinuation: CheckedContinuation<Void, Never>?
    private let yellowThreshold: Int
    private let maxSize: Int
    private var isDecoderAllowedToRun = false
    
    init(yellowThreshold: Int = 400, maxSize: Int = 600) {
        self.yellowThreshold = yellowThreshold
        self.maxSize = maxSize
    }
    
    func enqueue(_ item: Element) async{
        while items.count >= maxSize {
            await withCheckedContinuation{continuation in
                renderContinuation = continuation
            }
        }
        items.append(item)
        if items.count >= yellowThreshold {
            isDecoderAllowedToRun = true
            decodeContinuation?.resume()
            decodeContinuation = nil
        }
    }
    
    func dequeue() async -> Element {
        while items.isEmpty || !isDecoderAllowedToRun {
            if items.isEmpty {
                isDecoderAllowedToRun = false
            }
            await withCheckedContinuation{ continuation in
                decodeContinuation = continuation
            }
        }
        let item = items.removeFirst()
        
        renderContinuation?.resume()
        renderContinuation = nil
        return item
    }
    
    func clear() async {
        items.removeAll()
    }
}
