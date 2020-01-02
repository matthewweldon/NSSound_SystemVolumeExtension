//
//  NSSound extension.swift
//  iWannaSleep
//
//  Created by Marco on 02.01.20.
//  Copyright © 2020 Marco. All rights reserved.
//
//
//  ISSoundAdditions.m (ver 1.2 - 2012.10.27)
//
//    Created by Massimo Moiso (2012-09) InerziaSoft
//    based on an idea of Antonio Nunes, SintraWorks
//
// Permission is granted free of charge to use this code without restriction
// and without limitation, with the only condition that the copyright
// notice and this permission shall be included in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import CoreAudioKit


extension NSSound {
    //
    //    Return the ID of the default audio device; this is a C routine
    //
    //    IN:        none
    //    OUT:    the ID of the default device or AudioObjectUnknown
    //
    
    class func obtainDefaultOutputDevice() -> AudioDeviceID
    {
        var  theAnswer : AudioDeviceID = kAudioObjectUnknown
        var  theSize = UInt32(MemoryLayout.size(ofValue: theAnswer)) // needs to be converted to UInt32?
        var  theAddress : AudioObjectPropertyAddress
            
        theAddress = AudioObjectPropertyAddress.init(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        
        //first be sure that a default device exists
        if (!AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &theAddress) )    {
            print("Unable to get default audio device")
            return theAnswer
        }
        
        //get the property 'default output device'
        let theError : OSStatus = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &theAddress, UInt32(0), nil, &theSize, &theAnswer)
        if (theError != noErr) {
            print("Unable to get output audio device")
            return theAnswer
        }
        return theAnswer
    }

    //
    //    Return the ID of the default audio device; this is a category class method
    //    that can be called from outside
    //
    //    IN:        none
    //    OUT:    the ID of the default device or AudioObjectUnknown
    //
    class func defaultOutputDevice() -> AudioDeviceID
    {
        return obtainDefaultOutputDevice()
    }


    //
    //    Return the system sound volume as a float in the range [0...1]
    //
    //    IN:        none
    //    OUT:    (float) the volume of the default device
    //
    class func systemVolume() -> Float
    {
        var defaultDevID: AudioDeviceID = kAudioObjectUnknown
        var theSize = UInt32(MemoryLayout.size(ofValue: defaultDevID))
        var theError: OSStatus
        var theVolume: Float32 = 0
        var theAddress: AudioObjectPropertyAddress
        
        defaultDevID = obtainDefaultOutputDevice()
        if (defaultDevID == kAudioObjectUnknown) {
            print("Audio device not found!")
            return 0.0
        }        //device not found: return 0
        
        theAddress = AudioObjectPropertyAddress.init(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
        
        
        //be sure that the default device has the volume property
        if (!AudioObjectHasProperty(defaultDevID, &theAddress) ) {
            print("No volume control for device 0x%0x",defaultDevID)
            return 0.0
        }
        
        //now read the property and correct it, if outside [0...1]
        theError = AudioObjectGetPropertyData(defaultDevID, &theAddress, 0, nil, &theSize, &theVolume)
        if ( theError != noErr )    {
            print("Unable to read volume for device 0x%0x", defaultDevID)
            return 0.0
        }
        
        theVolume = theVolume > 1.0 ? 1.0 : (theVolume < 0.0 ? 0.0 : theVolume)
        
        return theVolume
    }

    //
    //    Set the volume of the default device
    //
    //    IN:        (float)the new volume
    //    OUT:    none
    //
    class func setSystemVolume(theVolume: Float)
    {
        var newValue: Float = theVolume
        var theAddress: AudioObjectPropertyAddress
        var defaultDevID: AudioDeviceID
        var theError: OSStatus = noErr
        var muted: UInt32
        var canSetVol: DarwinBoolean = true
        var muteValue: Bool
        var hasMute:Bool = true
        var canMute: DarwinBoolean = true
        
        defaultDevID = obtainDefaultOutputDevice()
        if (defaultDevID == kAudioObjectUnknown) {            //device not found: return without trying to set
            print("Audio Device unknown")
            return
        }
        
        //check if the new value is in the correct range - normalize it if not
        newValue = theVolume > 1.0 ? 1.0 : (theVolume < 0.0 ? 0.0 : theVolume)
        if (newValue != theVolume) {
            print("Tentative volume (%5.2f) was out of range; reset to %5.2f", theVolume, newValue)
        }
        
        theAddress = AudioObjectPropertyAddress.init(mSelector: kAudioDevicePropertyMute, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
        
        //set the selector to mute or not by checking if under threshold (5% here)
        //and check if a mute command is available
        muteValue = (newValue < 0.05)
        if (muteValue) {
            theAddress.mSelector = kAudioDevicePropertyMute
            hasMute = AudioObjectHasProperty(defaultDevID, &theAddress)
            if (hasMute) {
                theError = AudioObjectIsPropertySettable(defaultDevID, &theAddress, &canMute)
                if (theError != noErr || !(canMute.boolValue))
                {
                    canMute = false
                    print("Should mute device 0x%0x but did not succeed",defaultDevID)
                }
            }
            else {canMute = false}
        } else {
            theAddress.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume
        }
        
        // **** now manage the volume following the what we found ****
        
        //be sure the device has a volume command
        if (!AudioObjectHasProperty(defaultDevID, &theAddress)) {
            print("The device 0x%0x does not have a volume to set", defaultDevID)
            return
        }
        
        //be sure the device can set the volume
        theError = AudioObjectIsPropertySettable(defaultDevID, &theAddress, &canSetVol)
        if ( theError != noErr || !canSetVol.boolValue ) {
            print("The volume of device 0x%0x cannot be set", defaultDevID)
            return
        }
        
        //if under the threshold then mute it, only if possible - done/exit
        if (muteValue && hasMute && canMute.boolValue) {
            muted = 1
            theError = AudioObjectSetPropertyData(defaultDevID, &theAddress, 0, nil, UInt32(MemoryLayout.size(ofValue: muted)), &muted)
            
            if (theError != noErr) {
                print("The device 0x%0x was not muted",defaultDevID)
                return
            }
        } else {       //else set it
            theError = AudioObjectSetPropertyData(defaultDevID, &theAddress, 0, nil, UInt32(MemoryLayout.size(ofValue: newValue)), &newValue)
            if (theError != noErr) {
                print("The device 0x%0x was unable to set volume", defaultDevID)
            }
            //if device is able to handle muting, maybe it was muted, so unlock it
            if (hasMute && canMute.boolValue) {
                theAddress.mSelector = kAudioDevicePropertyMute
                muted = 0
                theError = AudioObjectSetPropertyData(defaultDevID, &theAddress, 0, nil, UInt32(MemoryLayout.size(ofValue: muted)), &muted)
            }
        }
        if (theError != noErr) {
            print("Unable to set volume for device 0x%0x", defaultDevID)
        }
    }


    //
    //    Increase the volume of the system device by a certain value
    //
    //    IN:        (float) amount of volume to increase
    //    OUT:    none
    //
    class func increaseSystemVolumeBy (amount:Float) {
        self.setSystemVolume(theVolume: self.systemVolume()+amount)
    }

    //
    //    Decrease the volume of the system device by a certain value
    //
    //    IN:        (float) amount of volume to decrease
    //    OUT:    none
    //
    class func decreaseSystemVolumeBy(amount: Float) {
        self.setSystemVolume(theVolume: self.systemVolume()-amount)
    }

    //
    //    IN:        (Boolean) if true the device is muted, false it is unmated
    //    OUT:        none
    //
    class func applyMute(_ m:Bool) {
        var defaultDevID: AudioDeviceID = kAudioObjectUnknown
        var theAddress: AudioObjectPropertyAddress
        var hasMute: Bool
        var canMute: DarwinBoolean = true
        var theError: OSStatus = noErr
        var muted: UInt32 = 0
        
        defaultDevID = obtainDefaultOutputDevice()
        if (defaultDevID == kAudioObjectUnknown) {            //device not found
            print("Audio device unknown")
            return
        }
        
        theAddress = AudioObjectPropertyAddress.init(mSelector: kAudioDevicePropertyMute, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)

        muted = m ? 1 : 0
        
        hasMute = AudioObjectHasProperty(defaultDevID, &theAddress)
        
        if (hasMute)
        {
            theError = AudioObjectIsPropertySettable(defaultDevID, &theAddress, &canMute)
            if (theError == noErr && canMute.boolValue)
            {
                theError = AudioObjectSetPropertyData(defaultDevID, &theAddress, 0, nil, UInt32(MemoryLayout.size(ofValue: muted)), &muted)
                if (theError != noErr) {
                    print("Cannot change mute status of device 0x%0x", defaultDevID)
                }
            }
        }
    }

    class func isMuted() -> Bool
    {
        var defaultDevID: AudioDeviceID = kAudioObjectUnknown
        var theAddress: AudioObjectPropertyAddress
        var hasMute: Bool
        var canMute: DarwinBoolean = true
        var theError: OSStatus = noErr
        var muted: UInt32 = 0
        var mutedSize = UInt32(MemoryLayout.size(ofValue: muted))
        
        defaultDevID = obtainDefaultOutputDevice()
        if (defaultDevID == kAudioObjectUnknown) {            //device not found
            print("Audio device unknown")
            return false                       // works, but not the best return code for this
        }
        
        theAddress = AudioObjectPropertyAddress.init(mSelector: kAudioDevicePropertyMute, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
        
        hasMute = AudioObjectHasProperty(defaultDevID, &theAddress)
        
        if (hasMute) {
            theError = AudioObjectIsPropertySettable(defaultDevID, &theAddress, &canMute)
            if (theError == noErr && canMute.boolValue) {
                theError = AudioObjectGetPropertyData(defaultDevID, &theAddress, 0, nil, &mutedSize, &muted)
                if (muted != 0) {
                    return true
                }
            }
        }
        return false
    }

}
