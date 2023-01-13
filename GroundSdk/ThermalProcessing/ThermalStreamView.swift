// Copyright (C) 2019 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import SdkCore

/// View that displays a thermal video stream.
public final class ThermalStreamView: StreamView, TextureLoader {

    /// Called at each render
    ///
    /// - Parameter lowest: spot at the lowest temperature.
    /// - Parameter hightest: spot at the  hightest temperature.
    /// - Parameter probe: probe spot.
    public var renderStatusBlock: ((_ lowest: ThermalProcSpot?,
                                    _ hightest: ThermalProcSpot?,
                                    _ probe: ThermalProcSpot?) -> Void)?

    /// Private thermal processing instance.
    private var tproc: ThermalProcVideo?
    /// Thermal processing instance.
    public var thermalProc: ThermalProcVideo? {
        get {
            return tproc
        }
        set {
            if tproc?.rendererIsStarted() == true {
                tproc?.stopRenderer()
            }
            tproc = newValue
            textureLoader = tproc != nil ? self : nil
        }
    }

    /// Thermal Camera model to used.
    public var thermalCamera = ThermalProcThermalCamera.lepton {
        willSet {
            if newValue != thermalCamera && tproc?.rendererIsStarted() == true {
                tproc?.stopRenderer()
            }
        }
    }

    public var textureSpec = TextureSpec.sourceDimensions

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Called to render a custom GL texture.
    ///
    /// - Parameter frame: frame data
    /// - Returns: 'true' on success, otherwise 'false'
    public func loadTexture(width: Int, height: Int, frame: TextureLoaderFrame?) -> Bool {
        if tproc?.rendererIsStarted() == false {
            tproc?.startRenderer(thermalCamera: thermalCamera, textureWidth: Int32(width), textureHeight: Int32(height))
        }

        if let frame = frame {
            tproc?.render(textureWidth: Int32(width), textureHeight: Int32(height),
                          frame: frame.frame, frameUserData: frame.userData, frameUserDataLength: frame.userDataLen,
                          mediaInfo: frame.mediaInfo) { status in
                if status.hasThermalData == true && status.calibrationState != .inProgress {
                    self.renderStatusBlock?(status.min, status.max, status.probe)
                } else {
                    self.renderStatusBlock?(nil, nil, nil)
                }
            }
        }
        return true
    }
}
