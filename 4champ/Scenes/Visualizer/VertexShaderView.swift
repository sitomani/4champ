//
//  MetalView.swift
//  ampplayer
//
//  Copyright © 2024 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import MetalKit

struct Bounds {
 let width: UInt16
 let height: UInt16
}

protocol StreamVisualiser: NSObjectProtocol {
  func update(leftChannel: UnsafePointer<Int16>, rightChannel: UnsafePointer<Int16>, frameCount: UInt32)
}

class VertexShaderView: MTKView, StreamVisualiser {
    var commandQueue: MTLCommandQueue!
    var leftBuffer: MTLBuffer!
    var rightBuffer: MTLBuffer!
    var frameCountBuffer: MTLBuffer!
    var scaleBuffer: MTLBuffer!
    var frameCount: UInt32 = 0
    lazy var pipelineState: MTLRenderPipelineState? = createPipelineState()

    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device?.makeCommandQueue()
        self.leftBuffer = device?.makeBuffer(length: MemoryLayout<Int16>.size * 4096, options: .storageModeShared)
        self.rightBuffer = device?.makeBuffer(length: MemoryLayout<Int16>.size * 4096, options: .storageModeShared)
        self.frameCountBuffer = device?.makeBuffer(length: MemoryLayout<UInt32>.size, options: .storageModeShared)
        self.scaleBuffer = device?.makeBuffer(length: MemoryLayout<Bounds>.size, options: .storageModeShared)
        self.framebufferOnly = false
    }

    func createPipelineState() -> MTLRenderPipelineState? {
        guard let device = device else { return nil }

        // Load shaders from the library
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat

        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    func update(leftChannel: UnsafePointer<Int16>, rightChannel: UnsafePointer<Int16>, frameCount: UInt32) {
        guard let leftBuffer = self.leftBuffer, let rightBuffer = self.rightBuffer else { return }
        self.frameCount = frameCount

        // Get a pointer to the Metal buffer's memory
        let bufferPointerLeft = leftBuffer.contents().assumingMemoryBound(to: Int16.self)
        let bufferPointerRight = rightBuffer.contents().assumingMemoryBound(to: Int16.self)

        let byteCount = Int(frameCount) * MemoryLayout<Int16>.size
        memcpy(bufferPointerLeft, leftChannel, byteCount)
        memcpy(bufferPointerRight, rightChannel, byteCount)

        // Trigger the rendering
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let drawable = self.currentDrawable,
              let renderPassDescriptor = self.currentRenderPassDescriptor,
              let pipelineState = pipelineState else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        // Set up the 4champ background color
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.07, 0.20, 0.34, 1.0)
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(leftBuffer, offset: 0, index: 0)
        renderEncoder?.setVertexBuffer(rightBuffer, offset: 0, index: 1)

        let frameCountPointer = frameCountBuffer.contents().bindMemory(to: UInt32.self, capacity: 1)
        frameCountPointer.pointee = frameCount
        renderEncoder?.setVertexBuffer(frameCountBuffer, offset: 0, index: 2)

        let scalePointer = scaleBuffer.contents().bindMemory(to: Bounds.self, capacity: 1)
        scalePointer.pointee = Bounds(width: UInt16(rect.size.width), height: UInt16(rect.size.height))
        renderEncoder?.setVertexBuffer(scaleBuffer, offset: 0, index: 3)

        renderEncoder?.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: Int(rect.size.width))

        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
