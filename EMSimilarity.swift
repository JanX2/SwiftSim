
//
//  EMSimilarity.swift
//  SwiftSim
//
//  Created by Evan Moss on 8/1/16.
//  Copyright © 2016 Enterprising Technologies LLC. All rights reserved.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Evan Moss
//  Copyright (c) 2022 Jan Weiß
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation


public typealias Sample = Double
public typealias Samples = [Sample]

public enum EMSimilarityMode {
    case Cosine
    case Tanimoto
    case Ochiai
    case JaccardIndex
    case JaccardDistance
    case Dice
    case Hamming
}

public enum EMVectorSizeMismatchMode {
    case Bail
    case Truncate
}

public class EMSimilarity {
public init() {}

    /** Similarity metric mode **/
    private var currentSimMode = [EMSimilarityMode.Cosine]
    
    /** Set the currentSimMode via push **/
    public func pushSimMode(mode: EMSimilarityMode) {
        self.currentSimMode.append(mode)
    }
    
    /** Pop the currentSimMode via pop if it won't make the stack empty **/
    public func popSimMode() {
        if self.currentSimMode.count > 1 {
            let _ = self.currentSimMode.popLast()
        }
    }
    
    /** Get the currently set similarity mode **/
    public func getCurrentSimMode() -> EMSimilarityMode? {
        return self.currentSimMode.last
    }
    
    /** Mismatch Mode **/
    private var currentMismatchMode = [EMVectorSizeMismatchMode.Bail]
    
    /** Set the currentMismatcMode via push **/
    public func pushMismatchMode(mode: EMVectorSizeMismatchMode) {
        self.currentMismatchMode.append(mode)
    }
    
    /** Pop the currentMismatchMode via pop if it won't make the stack empty **/
    public func popMismatchMode() {
        if self.currentMismatchMode.count > 1 {
            let _ = self.currentMismatchMode.popLast()
        }
    }
    
    /** Get the currently set mistmatch mode **/
    public func getCurrentMismatchMode() -> EMVectorSizeMismatchMode? {
        return self.currentMismatchMode.last
    }
    
    /** Dot Product **/
    private func dot(A: Samples, B: Samples) -> Sample {
        var x: Sample = 0
        for i in 0...A.count-1 {
            x += A[i] * B[i]
        }
        return x
    }
    
    /** Vector Magnitude **/
    private func magnitude(A: Samples) -> Sample {
        var x: Sample = 0
        for elt in A {
            x += elt * elt
        }
        return sqrt(x)
    }
    
    /** Cosine similarity **/
    private func cosineSim(A: Samples, B: Samples) -> Sample {
        return dot(A: A, B: B) / (magnitude(A: A) * magnitude(A: B))
    }
    
    /** Tanimoto similarity **/
    private func tanimotoSim(A: Samples, B: Samples) -> Sample {
        let Amag = magnitude(A: A)
        let Bmag = magnitude(A: B)
        let AdotB = dot(A: A, B: B)
        return AdotB / (Amag * Amag + Bmag * Bmag - AdotB)
    }
    
    /** Ochiai similarity **/
    private func ochiaiSim(A: Samples, B: Samples) -> Sample {
        let a = Set(A)
        let b = Set(B)
        
        return Sample(a.intersection(b).count) / sqrt(Sample(a.count) * Sample(b.count))
    }
    
    /** Jaccard index **/
    private func jaccardIndex(A: Samples, B: Samples) -> Sample {
        let a = Set(A)
        let b = Set(B)
        
        return Sample(a.intersection(b).count) / Sample(a.union(b).count)
    }
    
    /** Jaccard distance **/
    private func jaccardDist(A: Samples, B: Samples) -> Sample {
        return 1.0 - jaccardIndex(A: A, B: B)
    }
    
    /** Dice coeeficient **/
    private func diceCoef(A: Samples, B: Samples) -> Sample {
        let a = Set(A)
        let b = Set(B)
        
        return 2.0 * Sample(a.intersection(b).count) / (Sample(a.count) + Sample(b.count))
    }
    
    /** Hamming distance **/
    private func hammingDist(A: Samples, B: Samples) -> Sample {
        var x: Sample = 0
        
        if A.isEmpty {
            return x
        }
        
        for i in 0...A.count-1 {
            if A[i] != B[i] {
                x += 1
            }
        }
        
        return x
    }
    
    private let enforceEqualVectorSizes: Set<EMSimilarityMode> = [.Cosine, .Tanimoto, .Hamming]
    private let bailOnEmptyInput: Set<EMSimilarityMode> = [.Cosine, .Tanimoto, .Ochiai]
    private let allowEmptyInputs: Set<EMSimilarityMode> = [.Hamming]
    
    /**
     * Main compute mode
     * Sample types
     * Returns the similarity results or -1.0 on caught error
     */
    public func compute(A: Samples, B: Samples) -> Sample {
        // get the mode
        var mode = EMSimilarityMode.Cosine
        if let _mode = self.getCurrentSimMode() {
            mode = _mode
        }
        else {
            return -1
        }
        
        // are both vectors empty?
        if A.isEmpty && B.isEmpty && !allowEmptyInputs.contains(mode) {
            // divide by zero -> D.N.E.
            return -1
        }
        
        // is one of the vectors empty and would this case a divide by zero error?
        if bailOnEmptyInput.contains(mode) && (A.isEmpty || B.isEmpty) {
            return -1
        }
        
        // look for vector size mismatch for modes in enforceEqualVectorSizes
        if enforceEqualVectorSizes.contains(mode) && A.count != B.count {
            if let mismatchMode = self.getCurrentMismatchMode() {
                switch mismatchMode {
                case .Bail:
                    return -1
                case .Truncate:
                    let a = A.count < B.count ? A : B
                    let _b = A.count < B.count ? B : A
                    var b = Samples()
                    if a.count > 0 {
                        for i in 0...a.count-1 {
                            b.append(_b[i])
                        }
                    }
                    return compute(A: a, B: b)
                }
            }
            else {
                return -1
            }
        }
        
        switch mode {
        case .Cosine:
            return cosineSim(A: A, B: B)
        case .Tanimoto:
            return tanimotoSim(A: A, B: B)
        case .Ochiai:
            return ochiaiSim(A: A, B: B)
        case .JaccardIndex:
            return jaccardIndex(A: A, B: B)
        case .JaccardDistance:
            return jaccardDist(A: A, B: B)
        case .Dice:
            return diceCoef(A: A, B: B)
        case .Hamming:
            return hammingDist(A: A, B: B)
        }
    }
}
