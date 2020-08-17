//
//  ViewController.swift
//  bARcode
//
//  Created by rollacode on 06.08.2020.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Vision

class ARController: UIViewController {
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var scanInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var scanInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!

    var barcodesNodes: Dictionary<String, BarCodePlane> = [:]
    var barcodesProcessing = false
    let updateQueue = DispatchQueue(label: "com.bARCode.updateQueue")
    var displayLink: CADisplayLink?
    
    //===========================================
    // MARK: - Lifecycle -
    //===========================================
         
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        sceneView.session.run(ARWorldTrackingConfiguration.projectDefault)
        sceneView.session.delegate = self
//        sceneView.showsStatistics = true
        sceneView.scene.physicsWorld.contactDelegate = self
        UIApplication.shared.isIdleTimerDisabled = true
        
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkHandler))
            displayLink?.preferredFramesPerSecond = 15
            displayLink?.add(to: .main, forMode: .default)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(shoot))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        displayLink?.isPaused = true
    }
    
    private func resetTracking() {
        sceneView.session.run(ARWorldTrackingConfiguration.projectDefault,
                              options: [.resetTracking, .removeExistingAnchors])
        displayLink?.isPaused = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        displayLink = nil
    }
    
    //===========================================
    // MARK: - Barcode vision -
    //===========================================
    
    @objc private func displayLinkHandler() {
        self.createBarcodeDetectionRequest()
    }
    
    private func createBarcodeDetectionRequest() {
        guard !self.barcodesProcessing else { return }
        self.startBarcodeProcessing()

        let request = VNDetectBarcodesRequest(completionHandler: self.createOrUpdateBarcode)
        request.symbologies = [.QR, .UPCE, .I2of5, .I2of5Checksum,
                               .Aztec, .Code128, .Code39, .Code39Checksum,
                               .Code39FullASCII, .Code39FullASCIIChecksum,
                               .Code93, .Code93i, .DataMatrix, .EAN13,
                               .EAN8, .ITF14, .PDF417]
        let qrRequests = [request]
        DispatchQueue.main.async {
            do {
                self.scanInfoView.isHidden = self.barcodesNodes.count < 1
                guard let currentFrameBuffer = self.sceneView.session.currentFrame?.capturedImage else { return }
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: currentFrameBuffer, options: [:])
                try imageRequestHandler.perform(qrRequests)
            } catch { print("QR request error: " + error.localizedDescription) }
        }
    }
    
    private func createOrUpdateBarcode(with request: VNRequest, error: Error?) {
        guard error == nil else {
            print("Error reading bar codes: ", error?.localizedDescription ?? "unknown")
            self.endBarcodeProcessing()
            return
        }
        
        if let results = request.results {
            DispatchQueue.main.async {
                results.forEach { result in
                    guard let result = result as? VNBarcodeObservation,
                        let payload = result.payloadStringValue else {
                            self.endBarcodeProcessing()
                            return
                    }

                    guard let hitCenter = self.firstHit(from: result.boundingBox.center) else {
                        self.endBarcodeProcessing()
                        return
                    }

                    if let node = self.barcodesNodes[payload] {
                        node.setPosition(with: hitCenter)
                        node.updateOrientation(basedOn: hitCenter)
                    } else {
                        self.addNewARBarcode(with: hitCenter, payload)
                    }
                }
            
                self.endBarcodeProcessing()
            }
        } else { self.endBarcodeProcessing() }
    }
    
    private func addNewARBarcode(with hit: ARRaycastResult, _ payload: String) {
        updateQueue.async {
            let plane = BarCodePlane(payload: payload)
            self.sceneView.scene.rootNode.addChildNode(plane)
            self.barcodesNodes[payload] = plane
            
            plane.updateOrientation(basedOn: hit)
        }
    }
    
    private func startBarcodeProcessing() {
        self.barcodesProcessing = true
    }
    
    private func endBarcodeProcessing() {
        self.barcodesProcessing = false
    }
}

//===========================================
// MARK: - Shoot -
//===========================================

extension ARController: SCNPhysicsContactDelegate {
    
    @objc private func shoot() {
        let arBullet = ARBullet()
    
        let (direction, position) = cameraVector;
        arBullet.position = position
        let dir = direction * 1.3

        arBullet.physicsBody?.applyForce(dir, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(arBullet)
        
        //Destroy old bullets
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak arBullet] (timer) in
            arBullet?.removeFromParentNode()
        }
    }
    
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let nodeABitMask = contact.nodeA.physicsBody?.categoryBitMask,
            let nodeBBitMask = contact.nodeB.physicsBody?.categoryBitMask,
            nodeABitMask & nodeBBitMask == CollisionCategory.codes.rawValue & CollisionCategory.bullets.rawValue else { return }

        if let node = contact.nodeA as? BarCodePlane ?? contact.nodeB as? BarCodePlane {
            node.isRead ? node.unread() : node.read()
            
            DispatchQueue.main.async {
                self.scanInfoLabel.text = "scanned: \(node.payload)"
            }
        }
        
        if let node = contact.nodeA as? ARBullet ?? contact.nodeB as? ARBullet {
            node.removeFromParentNode()
        }
    }
}

//===========================================
// MARK: - Delegates -
//===========================================

extension ARController: ARSCNViewDelegate, ARSessionDelegate {
    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
        updateDisplayLink(with: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
        updateDisplayLink(with: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: camera.trackingState)
        updateDisplayLink(with: camera.trackingState)
    }

    // MARK: - ARSessionObserver
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
        sessionInfoView.isHidden = false
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        sessionInfoView.isHidden = false
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func updateDisplayLink(with trackingState: ARCamera.TrackingState) {
        switch trackingState {
        case .normal:
            displayLink?.isPaused = false
        default:
            displayLink?.isPaused = true
        }
    }

    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal and vertical surfaces."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""

        }

        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
}


//===========================================
// MARK: - Utils -
//===========================================
private extension ARController {
    var cameraVector: (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = frame.camera.transform.matrix() // 4x4 transform matrix describing camera in world space
            return (mat.backVector, mat.position)
        }
        return (SCNVector3(0, 0, 0), SCNVector3(0, 0, 0))
    }
    
    func firstHit(from point: CGPoint) -> ARRaycastResult? {
        let bounds = CGPoint(x: self.sceneView.bounds.width, y: self.sceneView.bounds.height)
            * CGPoint(x: point.y, y: point.x)
        guard let query = self.sceneView.raycastQuery(from: bounds, allowing: .estimatedPlane, alignment: .any) else { return nil }
        return self.sceneView.session.raycast(query).first
    }
}

private extension ARWorldTrackingConfiguration {
    static var projectDefault: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        return configuration
    }
}
