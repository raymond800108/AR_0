//
//  ViewController.swift
//  WorldTracking_0
//
//  Created by shu chuan yao on 2019/11/6.
//  Copyright © 2019 shu chuan yao. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Firebase

class ViewController: UIViewController, ARSCNViewDelegate,UITextFieldDelegate{

    @IBOutlet weak var addNode: UIButton!
    @IBOutlet weak var draw: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    private let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    private var currPlaneId: Int = 0

    var robotArray = [SCNNode]()
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.showsStatistics = true
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        
    self.sceneView.debugOptions=[ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
   
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        configuration.planeDetection = [.horizontal,.vertical]

        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    ///////////////////////    robot control scetion part     ////////////////////
    
    func rotate(robot:SCNNode){
       robot.runAction(SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi/180), z: 0, duration: 0.5))
    }
    @IBAction func rotateRobot(_ sender: Any) {
        if !robotArray.isEmpty{
                  for robot in robotArray{
                      rotate(robot:robot)
                  }
              }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            let touchLocation = touch.location(in: sceneView)
            let result = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if let hitResult = result.first{
                addRobot(atLocation: hitResult)
            }
        }
    }

    
    func addRobot(atLocation location:ARHitTestResult){
        let Robotscene = SCNScene(named: "art.scnassets/KR-10.scn")!
        if let robotNode = Robotscene.rootNode.childNode(withName: "Mesh", recursively: true){
            robotNode.position = SCNVector3(
                x: location.worldTransform.columns.3.x,
                y: location.worldTransform.columns.3.y,
                z: location.worldTransform.columns.3.z )
            robotArray.append(robotNode)
            sceneView.scene.rootNode.addChildNode(robotNode)
        }
    }
    
    func createPlaneNode(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let scenePlaneGeometry = ARSCNPlaneGeometry(device: metalDevice!)
        scenePlaneGeometry?.update(from: planeAnchor.geometry)
        let planeNode = SCNNode(geometry: scenePlaneGeometry)
        planeNode.name = "\(currPlaneId)"
        planeNode.opacity = 0.75
        if planeAnchor.alignment == .horizontal {
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        } else {
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        }
        currPlaneId += 1
        return planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // only care about detected planes (i.e. `ARPlaneAnchor`s)
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeNode = createPlaneNode(planeAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // only care about detected planes (i.e. `ARPlaneAnchor`s)
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("Updating plane anchor")
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        let planeNode = createPlaneNode(planeAnchor: planeAnchor)
        node.addChildNode(planeNode)
        
//        let planeNode = node.childNode(withName: node.name!, recursively: false)
//        let g = planeNode?.geometry as? ARSCNPlaneGeometry
//        g?.update(from: planeAnchor.geometry)
//        planeNode?.geometry = g
//        node.addChildNode(planeNode!)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else { return }
        print("Removing plane anchor")
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    /*
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor{
            let planeAnchor = anchor as! ARPlaneAnchor
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x),height:CGFloat(planeAnchor.extent.z))
            let planeNode =  SCNNode()
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [gridMaterial]
            
            planeNode.geometry  = plane
            
            node.addChildNode(planeNode)
        }
        else{
            return
        }
    }
    */
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        
        guard let pointOfView = sceneView.pointOfView else{return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = orientation+location
        DispatchQueue.main.async {
            if self.draw.isHighlighted{
                let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.02))
                sphereNode.position = currentPositionOfCamera
                self.sceneView.scene.rootNode.addChildNode(sphereNode)
                sphereNode.geometry?.firstMaterial?.diffuse.contents=UIColor.white
            }
            
            else{
                let pointer = SCNNode(geometry: SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.01/2))
                
                pointer.position = currentPositionOfCamera
                self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                    if node.geometry is SCNBox{
                        node.removeFromParentNode()
                    }
                }
                self.sceneView.scene.rootNode.addChildNode(pointer)
                pointer.geometry?.firstMaterial?.diffuse.contents=UIColor.white
            }
        }
    }
    var pointXList = [Float]()
    var pointYList = [Float]()
    var pointZList = [Float]()
    
    @IBAction func add(_ sender: Any) {
        let node = SCNNode()
        guard let pointOfView = sceneView.pointOfView else{return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = orientation+location
        
        node.geometry = SCNSphere(radius: 0.05)
        node.geometry?.firstMaterial?.diffuse.contents=UIColor.systemPink
        node.position = currentPositionOfCamera
        self.sceneView.scene.rootNode.addChildNode(node)
        
        pointXList.append(location.x)
        pointYList.append(location.y)
        pointZList.append(location.z)
        
        
        // send the point corridnates to Firebase
        repeat{
            let messageDB = Database.database().reference().child("Messages")
            let messageDictionary = ["X": pointXList,"Y":pointYList,"Z":pointZList,"Num":pointXList.count] as [String : Any]
            
            messageDB.setValue(messageDictionary)
            
        }while pointXList.count>10
        
    }
    
    
    
    @IBAction func reset(_ sender: Any) {
        
        let messageDB = Database.database().reference().child("Messages")
        let messageDictionary = ["X":0,"Y":0,"Z":0,"Num":0] as [String : Any]
        
        messageDB.setValue(messageDictionary)
        pointXList.removeAll()
        pointYList.removeAll()
        pointZList.removeAll()
        
        self.sceneView.session.pause()
        
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in node.removeFromParentNode()
            
        }
        self.sceneView.session.run(configuration,options: [.resetTracking,.removeExistingAnchors])
    }
    
    
}


// extra function for conditions
func +(left:SCNVector3,right:SCNVector3)->SCNVector3{
    return SCNVector3Make(left.x+right.x, left.y+right.y, left.z+right.z)
}
