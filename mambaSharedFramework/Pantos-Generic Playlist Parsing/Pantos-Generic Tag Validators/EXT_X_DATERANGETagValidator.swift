//
//  EXT_X_DATERANGEValidator.swift
//  mamba
//
//  Created by Robert Galluccio on 28/03/2020.
//  Copyright © 2020 Comcast Corporation.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License. All rights reserved.
//

import Foundation

/// This class provides special validation for EXT-X-DATERANGE tags on top of the regular `GenericDictionaryTagValidator`.
class EXT_X_DATERANGETagValidator: PlaylistTagValidator {
    
    private let genericDictionaryTagValidator: GenericDictionaryTagValidator
    
    init() {
        // All of the generic dictionary tag validation still applies;
        // however there will need to be some extra validation on top for EXT-X-DATERANGE.
        // Therefore, we will compose this validation and make use of the pre-existing
        // GenericDictionaryTagValidator.
        self.genericDictionaryTagValidator = GenericDictionaryTagValidator(tag: PantosTag.EXT_X_DATERANGE, dictionaryValueIdentifiers: [
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.id, optional: false, expectedType: String.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.classAttribute, optional: true, expectedType: String.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.startDate, optional: false, expectedType: Date.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.endDate, optional: true, expectedType: Date.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.duration, optional: true, expectedType: Double.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.plannedDuration, optional: true, expectedType: Double.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.scte35Cmd, optional: true, expectedType: String.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.scte35Out, optional: true, expectedType: String.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.scte35In, optional: true, expectedType: String.self),
            DictionaryTagValueIdentifierImpl(valueId: PantosValue.endOnNext, optional: true, expectedType: Bool.self)
        ])
    }
    
    func validate(tag: PlaylistTag) -> [PlaylistValidationIssue]? {
        let genericValidationIssues = genericDictionaryTagValidator.validate(tag: tag)
        let endOnNextValidationIssues = endOnNextValidation(tag: tag)
        let durationEndDateValidationIssues = durationEndDateValidation(tag: tag)
        
        var validationIssues: [PlaylistValidationIssue]?
        if let genericIssues = genericValidationIssues {
            validationIssues = validationIssues ?? []
            validationIssues?.append(contentsOf: genericIssues)
        }
        if let endOnNextIssues = endOnNextValidationIssues {
            validationIssues = validationIssues ?? []
            validationIssues?.append(contentsOf: endOnNextIssues)
        }
        if let durationEndDateIssues = durationEndDateValidationIssues {
            validationIssues = validationIssues ?? []
            validationIssues?.append(contentsOf: durationEndDateIssues)
        }
        
        return validationIssues
    }
    
    // END-ON-NEXT
    //
    // An enumerated-string whose value MUST be YES.
    //
    // An EXT-X-DATERANGE tag with an END-ON-NEXT=YES attribute MUST have a
    // CLASS attribute.
    //
    // An EXT-X-DATERANGE tag with an END-ON-NEXT=YES attribute MUST NOT
    // contain DURATION or END-DATE attributes.
    private func endOnNextValidation(tag: PlaylistTag) -> [PlaylistValidationIssue]? {
        guard let endOnNext = tag.value(forValueIdentifier: PantosValue.endOnNext) as Bool? else {
            return nil
        }
        
        var validationIssues = [PlaylistValidationIssue]()
        
        // value MUST be YES.
        if !endOnNext {
            validationIssues.append(PlaylistValidationIssue(description: .EXT_X_DATERANGEEND_ON_NEXTValueMustBeYES, severity: .error))
        }
        
        // An EXT-X-DATERANGE tag with an END-ON-NEXT=YES attribute MUST have a CLASS attribute.
        if tag.value(forValueIdentifier: PantosValue.classAttribute) == nil {
            validationIssues.append(PlaylistValidationIssue(description: .EXT_X_DATERANGETagWithEND_ON_NEXTMustHaveCLASSAttribute, severity: .error))
        }
        
        // An EXT-X-DATERANGE tag with an END-ON-NEXT=YES attribute MUST NOT contain DURATION or END-DATE attributes.
        if tag.value(forValueIdentifier: PantosValue.duration) != nil {
            validationIssues.append(PlaylistValidationIssue(description: .EXT_X_DATERANGETagWithEND_ON_NEXTMustNotContainDURATION, severity: .error))
        }
        if tag.value(forValueIdentifier: PantosValue.endDate) != nil {
            validationIssues.append(PlaylistValidationIssue(description: .EXT_X_DATERANGETagWithEND_ON_NEXTMustNotContainEND_DATE, severity: .error))
        }
        
        return validationIssues.isEmpty ? nil : validationIssues
    }
    
    // If a Date Range contains both a DURATION attribute and an END-DATE
    // attribute, the value of the END-DATE attribute MUST be equal to the
    // value of the START-DATE attribute plus the value of the DURATION
    // attribute.
    private func durationEndDateValidation(tag: PlaylistTag) -> [PlaylistValidationIssue]? {
        guard let startDate = tag.value(forValueIdentifier: PantosValue.startDate) as Date? else {
            // The failure will be caught in the generic validation, since start date is required.
            return nil
        }
        guard let duration = tag.value(forValueIdentifier: PantosValue.duration) as Double?,
            let endDate = tag.value(forValueIdentifier: PantosValue.endDate) as Date? else {
                return nil
        }
        
        var validationIssues = [PlaylistValidationIssue]()
        let expectedEndDate = startDate.addingTimeInterval(duration)
        if expectedEndDate != endDate {
            validationIssues.append(PlaylistValidationIssue(description: .EXT_X_DATERANGEValidatorDURATIONAndEND_DATEMustMatchWithSTART_DATE,
                                                            severity: .error))
        }
        
        return validationIssues.isEmpty ? nil : validationIssues
    }
}