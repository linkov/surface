//
//  ViewController.swift
//  Surface
//
//  Created by Alex Linkov on 7/1/20.
//  Copyright © 2020 SDWR. All rights reserved.
//

import UIKit
import VertexKit
import PixelKit
import RenderKit
import LiveValues
import Photos

import SwiftMetal

class ViewController: UIViewController {
    
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var panelView: UIView!
    var sliderValue: LiveFloat!

    @IBOutlet weak var stopRecButton: UIButton!
    @IBOutlet weak var startRecButton: UIButton!
    var recorder: RecordPIX!
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.wantsLayer = true
        view.layer.backgroundColor = UIColor.black.cgColor
        
        sliderValue = 1.0
        recorder = RecordPIX()
        recorder.realtime = true
        runNoiseTest1()
    }
    @IBAction func sliderDidSlide(_ sender: UISlider) {
        
        sliderValue = LiveFloat(sender.value)
        
    }
    
    @IBAction func didTapStart(_ sender: Any) {
    
     
        startRec()
    
    }
    
    @IBAction func didTapStop(_ sender: Any) {
        
        stopRecAndSave()
    }
    
    func startRec() {
        

        
        do {
            try recorder.startRec()
        }  catch {
            print("Unexpected error: \(error).")
        }
        
        
        
        
    }
    
    func stopRecAndSave() {
        
        let err = try! recorder.stopRec({ (URL) in
            self.saveInPhotoLibrary(URL)
        }, didError: { (Error) in
            
            print(Error)
            
        })
        
    }
    
    private func saveInPhotoLibrary(_ url:URL){
        PHPhotoLibrary.shared().performChanges({

            //add video to PhotoLibrary here
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { completed, error in
            if completed {
                print("save complete! path : " + url.absoluteString)
            }else{
                print("save failed")
            }
        }
    }
    
    
    func runNoiseTest1() {
        
            PixelKit.main.render.bits = ._16
             let camera = CameraPIX()

            let particlesCountResulution: Resolution = .square(1000)
      
            let res: Resolution = .fullscreen
     
        let uniforms: [MetalUniform] = [
            MetalUniform(name: "t", value: .touchX * 11300),
             MetalUniform(name: "vv", value: .touchY * 11300),
            MetalUniform(name: "d", value: .live / 30),
        ]
        let metal = MetalPIX(at: res, uniforms: uniforms, code:
            """
            float i = floor(v);
            float f = fract(v);
            float y = fract(sin(dot(float2(u,v),float2(200.0 / in.vv,8.233)))*1358.5453123 / in.t + in.d);
            pix = float4(y, v, 1.0, 1.0);
            """
        )

        
            let pres: Resolution = res / 8
            let uv = MetalPIX._uv(at: pres)
            
        
            let feed = FeedbackPIX()
            feed.input = uv - 0.5
             feed.feedPix = feed._displace(with: camera, distance: .touchX + 0.5)._cross(with: uv - 0.5, fraction: .touchY + 0.5)
        
        
        let textPixx = TextPIX(at: res)
        textPixx.text = "         Ghost"

//
//        let selectImage1 = PolygonPIX(at: res)
//        selectImage1.radius = 0.05
//        selectImage1.rotation = .live / 40
//
        
            // First we create the source particle pixels with a noise pix
            let noise = NoisePIX(at: res)
          
            noise.colored = true
            noise.octaves = 4
        //noise.zPosition = .random(in: 0.1 ... 0.8)
        noise.zoom = LiveFloat({ () -> (CGFloat) in
            return CGFloat(self.slider.value)
        })
       //     noise.zPosition = .live / 50
        
        
        
        
            let particles = ParticlesUV3DPIX(at: res)
        particles.vtxPixIn = (noise - 0.5  - textPixx )  * (metal - 0.5  - textPixx ) + (textPixx + 12.2) & feed
        particles.color = LiveColor(.blue)
        
        
          

        
        
            let final: PIX = particles
            final.view.frame = view.bounds
            final.view.checker = false
            view.addSubview(final.view)
           recorder.input = particles
        
        view.bringSubviewToFront(panelView)
        view.bringSubviewToFront(startRecButton)
        view.bringSubviewToFront(stopRecButton)
    }
    
    
    
    
    func runTouchableForceField() {
        
        
        
        
        

        
        
        
        
        
       PixelKit.main.render.bits = ._16
        
        
        let camera = CameraPIX()
        let res: Resolution = .fullscreen
        let pres: Resolution = res / 8
        let uv = MetalPIX._uv(at: pres)
        
        let selectImage1 = PolygonPIX(at: res)
        selectImage1.radius = 0.05
        selectImage1.rotation = .live / 40
        

        
        let selectImage2 = PolygonPIX(at: res)
        selectImage2.radius = 0.05
        selectImage2.rotation = .live / 20
        
        

        let feed = FeedbackPIX()
        feed.input = uv - 0.5
        feed.feedPix = feed._cross(with: uv - 0.5, fraction:  1)
        
        selectImage1.position = LivePoint(CGPoint(x: -0.1, y: 0.5 - 0.2))
        
        selectImage2.position = LivePoint(CGPoint(x: 0.5 * Double(res.aspect) - 0.15, y: 0.5 - 0.2))
        
        
        let particles = ParticlesUV3DPIX(at: res)
         particles.vtxPixIn = feed
         particles.size = 2.0
        particles.mapAlpha = true
        particles.color = LiveColor(r:  LiveFloat.noise() + 0.5, g:  LiveFloat.noise() + 0.5, b: .motionGyroZ + 0.5, a: 1.0)
        
        
        particles._displace(with: uv, distance: LiveFloat.noise())
        
//        let feed2 = particles._feed { feed in
//            return feed + particles
//        }

        
        

        
        
        
        let finalPix = particles * selectImage1._twirl(0.05)   +   selectImage2._twirl(-0.02)
        finalPix.view.frame = view.bounds
        finalPix.view.checker = false
        view.addSubview(finalPix.view)
        
        
    }
    
    
    
    
    
    
    
    
    /// Examples
    
    
    func runParticleFieldxample() {
    
        
        let polygon = PolygonPIX(at: ._128)
                
        PixelKit.main.render.bits = ._16

        let res: Resolution = .fullscreen
        let pres: Resolution = res / 8

        let puv = MetalPIX(at: pres, uniforms: [
            MetalUniform(name: "aspct", value: pres.aspect)
            ], code:
            """
            pix = float4((u - 0.5) * in.aspct,
                         v - 0.5, 0, 0);
            """
        )

        let noise = NoisePIX(at: res)
        noise.colored = true
        
        let feed1 = puv._feed { feed in
            let fx = MetalMergerEffectPIX(uniforms: [
                    MetalUniform(name: "aspct",
                                 value: pres.aspect),
                    MetalUniform(name: "wind",
                                 value: 0.001),
                    MetalUniform(name: "force",
                                value: 0.01),
                    MetalUniform(name: "thresh",
                                 value: 0.001)
                ], code:
                """
                float x = inputA.x;
                float y = inputA.y;
                float xu = inputA.z;
                float yv = inputA.w;
                float4 b = inTexB.sample(s,
                    float2(posX/in.aspct+0.5,y+0.5));
                float vx = b.x * in.force;
                float vy = b.y * in.force;
                float vxy = sqrt(pow(vx, 2) + pow(vy, 2));
                if (vxy > in.thresh) {
                    x += vx;
                    y += vy;
                } else {
                    x = xu;
                    y = yv;
                }
                pix = float4(x,y,0,1);
                """
            )
            fx.inputA = feed._RGtoBA(with: puv)
            fx.inputB = noise - 0.5
            return fx
        }

        let particles = ParticlesUV3DPIX(at: res)
        particles.vtxPixIn = feed1
        particles.color = LiveColor(lum: 1.0, a: 0.5)

        let feed2 = particles._feed { feed in
            return feed + particles
        }

        let finalPix = feed2
        finalPix.view.frame = view.bounds
        finalPix.view.checker = false
        view.addSubview(finalPix.view)
    
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func runNoisePlaneExample() {
        
        PixelKit.main.render.bits = ._16

        let res: Resolution = .fullscreen
        let pres: Resolution = .fullscreen

        let uv = MetalPIX._uv(at: pres)
        let puv = (uv - 0.5) * pres.aspect * .red
                + (uv - 0.5) * .green

        let noise = NoisePIX(at: pres)
        noise.colored = true
        noise.octaves = 4
        noise.zoom = 0.25
        noise.zPosition = .live / 10

        let gradient = GradientPIX(at: pres)
        gradient.direction = .radial

        let map = puv + (noise - 0.5) * (gradient !** 0.5)

        let particles = ParticlesUV3DPIX(at: res)
        particles.vtxPixIn = map
        particles.color = LiveColor(lum: 1.0, a: 0.5)

        let finalPix = particles
        finalPix.view.frame = view.bounds
        finalPix.view.checker = false
        view.addSubview(finalPix.view)
    }
    
    func runNoiseFlowExample() {
        
        PixelKit.main.render.bits = ._16

        let res: Resolution = .fullscreen
        let pres: Resolution = .square(Int(sqrt(1_000_000)))

        let uv = MetalPIX._uv(at: pres)

        let feed = FeedbackPIX()
        feed.input = uv - 0.5

        let noise = NoisePIX(at: pres)
        noise.colored = true
        noise.zPosition = .live / 10

        feed.feedPix = feed
            ._displace(with: noise, distance: .touchX + 0.5)
            ._cross(with: uv - 0.5, fraction: .touchY + 0.5)

        let particles = ParticlesUV3DPIX(at: res)
        particles.vtxPixIn = feed
        particles.color = LiveColor(lum: 1.0, a: 0.5)

        let finalPix = particles
        finalPix.view.frame = view.bounds
        finalPix.view.checker = false
        view.addSubview(finalPix.view)
    }
    
    func showCameraFeild() {
                 PixelKit.main.render.bits = ._16
                   let camera = CameraPIX()
                   
                 let res: Resolution = .iPhoneX(.portrait)
                 let pres: Resolution =  res / 8

                 let uv = MetalPIX._uv(at: pres)

                 let feed = FeedbackPIX()
                 feed.input = uv - 0.5

                 let noise = NoisePIX(at: pres)
                 noise.colored = true
                 noise.zPosition = .live / 10

                feed.feedPix = feed._cross(with: uv - 0.5, fraction:  1)



                   
                 let particles = ParticlesUV3DPIX(at: res)
                 particles.vtxPixIn = feed
                 particles.size = 2.0
                particles.mapAlpha = true
                particles.color = LiveColor(r: .touchX + 0.5, g: .touchY + 0.5, b: .motionGyroZ + 0.5, a: 1.0)

        
             // let point = particles.point(of: .touchXY)
                             
                   
                 let finalPix = particles
                 finalPix.view.frame = view.bounds
                 finalPix.view.checker = false
                 view.addSubview(finalPix.view)
    }
    
    
    func runVertexKitDemo() {
         PixelKit.main.render.bits = ._16

         let pres: Resolution = .square(Int(sqrt(1_000_000)))

        let noise = NoisePIX(at: pres)
         noise.colored = true
         noise.octaves = 5
         noise.zPosition = .live
         noise.zPosition *= 0.01
         
         let res: Resolution = .fullscreen
         
         let particles = ParticlesUV3DPIX(at: res)
         particles.vtxPixIn = noise - 0.5
         particles.color = LiveColor(lum: 1.0, a: 0.1)
         
         let final: PIX = particles
         final.view.frame = view.bounds
         final.view.checker = false
         view.addSubview(final.view)
    }
    
    func runPixelKitDemo1()  {
        
        let circlePix = CirclePIX(at: .fullscreen)

         let blurPix = BlurPIX()
         blurPix.input = circlePix
         blurPix.radius = 0.25

         let finalPix: PIX = blurPix
         finalPix.view.frame = view.bounds
         view.addSubview(finalPix.view)
    }
    
    func runMetalDemo1() {
        
        let uniforms: [MetalUniform] = [
            MetalUniform(name: "x", value: .touchX),
            MetalUniform(name: "y", value: .touchY)
        ]
        let metal = MetalPIX(at: .fullscreen, uniforms: uniforms, code:
            """
            float x = u - in.x - 0.5;
            float y = v - in.y - 0.5;
            float a = abs(x) * abs(y);
            float c = pow(1.0 - a, 10.0);
            pix = float4(c, c, c, 1.0);
            """
        )
        let final: PIX = metal
        final.view.frame = view.bounds
        view.addSubview(final.view)
    }
    
    
    func runMetalDemo2() {
        
        let circle = CirclePIX(at: .fullscreen)
        let polygon = PolygonPIX(at: .fullscreen)
        let metalMerger = MetalMergerEffectPIX(uniforms: [], code:
            """
            pix = float4(0.0, inputA[0], inputB[0], 1.0);
            """
        )
        metalMerger.inputA = circle
        metalMerger.inputB = polygon
        let final: PIX = metalMerger
        final.view.frame = view.bounds
        view.addSubview(final.view)
    }
    
    func runSwiftMetalDemo1() {
        
        let add: SMFunc<SMFloat4> = function { args -> SMFloat4 in
            let a = args[0] as! SMFloat4
            let b = args[1] as! SMFloat4
            return a + b
        }
        let shader = SMShader { uv in
            let a = float4(0.1, 0.0, 0.0, 1.0)
            let b = float4(0.2, 0.0, 0.0, 1.0)
            let t = SMTexture(image: UIImage(named: "photo1")!)!
            let c: SMFloat4 = add.call(a, a) * add.call(b, b) + t
            return c
        }
        let res = CGSize(width: 1024, height: 1024)
        let render: SMTexture = try! SMRenderer.render(shader, at: res)
        let image: UIImage = try! render.image()
        let texture: MTLTexture = render.texture as! MTLTexture
        
//        imageView.image = image
    }

}

