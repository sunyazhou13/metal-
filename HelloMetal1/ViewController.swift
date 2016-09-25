//
//  ViewController.swift
//  HelloMetal1
//
//  Created by sunyazhou on 2016/9/25.
//  Copyright © 2016年 Baidu, Inc. All rights reserved.
//

import UIKit
import QuartzCore
import MetalKit
//1.Create a MTLDevice
//2.Create a CAMetalLayer
//3.Create a Vertex Buffer
//4.Create a Vertex Shader
//5.Create a Fragment Shader
//6.Create a Render Pipeline
//7.Create a Command Queue

class ViewController: UIViewController {
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    let vertexData: [Float] = [0.0,1.0,0.0,
                               -1.0,-1.0,0.0,
                               1.0, -1.0, 0.0]
    var vertexBuffer:MTLBuffer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    var timer: CADisplayLink! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //1. 创建设备
        device = MTLCreateSystemDefaultDevice()
        
        //2. 创建CAMetalLayer
        metalLayer  = CAMetalLayer() //1
        metalLayer.device = device   //2
        metalLayer.pixelFormat = .bgra8Unorm //3
        metalLayer.framebufferOnly = true //4
        metalLayer.frame = view.layer.frame //5
        view.layer.addSublayer(metalLayer) //6
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0]) //1
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: .cpuCacheModeWriteCombined) //2
        
        //1
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary?.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary!.makeFunction(name: "basic_vertex")
        
        // 2
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction =  fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // 3
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            Swift.print("Failed to create pipeline state, error ")
        }
        
        commandQueue = device.makeCommandQueue()
        timer = CADisplayLink(target: self, selector: #selector(ViewController.gameloop))
        timer.add(to: .main, forMode: .defaultRunLoopMode)
        
    }

    
    func render() {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        let drawable = metalLayer.nextDrawable()
        renderPassDescriptor.colorAttachments[0].texture = drawable?.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 104.0/255.0, 5.0/255.0, 1)
        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderEncoderOpt = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        if renderEncoderOpt != nil {
            renderEncoderOpt.setRenderPipelineState(pipelineState)
            renderEncoderOpt.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
            renderEncoderOpt.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            renderEncoderOpt.endEncoding()
        }
        if drawable != nil {
            commandBuffer.present(drawable!)
            commandBuffer.commit()
        }
    }
    
    func gameloop() {
        autoreleasepool {
            
            self.render()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

