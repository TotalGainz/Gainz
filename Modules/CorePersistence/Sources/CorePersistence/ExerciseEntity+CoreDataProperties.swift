//  ExerciseEntity+CoreDataProperties.swift
//  CorePersistence
//
//  Generated accessors for ExerciseEntity attributes.
//  Created for Gainz on 27 May 2025.
//

#if canImport(CoreData)
import Foundation
import CoreData

extension ExerciseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseEntity> {
        return NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var primaryMuscles: [String]?
    @NSManaged public var secondaryMuscles: [String]?
    @NSManaged public var mechanicalPattern: String?
    @NSManaged public var equipment: String?
    @NSManaged public var isUnilateral: Bool
}

extension ExerciseEntity : Identifiable {}

#endif
