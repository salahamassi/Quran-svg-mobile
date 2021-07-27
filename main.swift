//
//  main.swift
//  Qurans vg mobile
//
//  Created by Salah Amassi on 26/07/2021.
//

import Foundation


// remove unneeded layers
for i in 0..<603 {
    let pageNumber = i < 9 ? "00\(i+1)" : i < 99 ? "0\(i+1)" : "\(i+1)"
    print("pageNumber", pageNumber)
    tryToRemoveExtraShapes(pageNumber: pageNumber)
}

// remove extra margin
for i in 0..<603 {
    let pageNumber = i < 9 ? "00\(i+1)" : i < 99 ? "0\(i+1)" : "\(i+1)"
    print("pageNumber", pageNumber)
    let path = "output/\(pageNumber)_updated.svg"
    bash(command: "inkscape", arguments: ["--export-filename=\(path)", "--export-area-drawing", path])
}

func tryToRemoveExtraShapes(pageNumber: String) {
    let path = "input/\(pageNumber).svg"
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let document = try XMLDocument(data: data, options: .documentTidyXML)
        
        for node in try document.nodes(forXPath: "//g") {
            guard let element = node as? XMLElement,
                  let elementAttributeIdValue = element.attribute(forName: "id")?.stringValue,
                  let children = element.children else { continue }
            
            if elementAttributeIdValue == "g10" {
                for (index, innerNode) in children.enumerated() {
                    guard let innerElement = innerNode as? XMLElement,
                          let innerElementAttributeIdValue = innerElement.attribute(forName: "id")?.stringValue else { continue }
                    if innerElementAttributeIdValue == "g54" || (index == 1 && children.count >= 4) {
                        element.removeChild(at: index)
                    }
                    
                    if innerElementAttributeIdValue == "g12" || index == 0 {
                        tryToRemoveBorder(rootElement: innerElement)
                    }
                    
                    print("second level g id \(innerElementAttributeIdValue)")
                }
            }
        }
        
        let xmlData = document.xmlData(options: .nodePrettyPrint)
        
        let path = "output/\(pageNumber)_updated.svg"
        
        try? xmlData.write(to: URL(fileURLWithPath: path))
        
    } catch {
        print(error)
    }
    
}

// g12 element
func tryToRemoveBorder(rootElement: XMLElement) {
    guard let children = rootElement.children else { return }
    for node in children {
        guard let element = node as? XMLElement,
              let children = node.children else { continue }
        for (index, innerNode) in children.enumerated() {
            guard let innerElement = innerNode as? XMLElement,
                  let innerElementAttributeIdValue = innerElement.attribute(forName: "id")?.stringValue else { continue }
            if !innerElementAttributeIdValue.starts(with: "g") {
                element.removeChild(at: index)
                print("innerElementAttributeIdValue", innerElementAttributeIdValue)
            } else {
                tryToRemoveHezpShape(rootElement: innerElement)
            }
        }
    }
}

func tryToRemoveHezpShape(rootElement: XMLElement) {
    guard let children = rootElement.children else { return }
    for (index, node) in children.enumerated() {
        guard let element = node as? XMLElement,
              let elementAttributeDValue = element.attribute(forName: "d")?.stringValue else { continue }
        if !elementAttributeDValue.starts(with: "m 0,0 c -0.0") && !elementAttributeDValue.starts(with: "m 0,0 c 0.247") { // not ayha shape or surah shape
            rootElement.removeChild(at: index)
        }
    }
}

// shell helper
func shell(launchPath: String, arguments: [String]) -> String
{
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)!
    if output.count > 0 {
        //remove newline character.
        let lastIndex = output.index(before: output.endIndex)
        return String(output[output.startIndex ..< lastIndex])
    }
    return output
}

@discardableResult
func bash(command: String, arguments: [String]) -> String {
    let whichPathForCommand = shell(launchPath: "/bin/bash", arguments: [ "-l", "-c", "which \(command)" ])
    return shell(launchPath: whichPathForCommand, arguments: arguments)
}
