import SwiftData

enum PlungeSessionSchemaV1: VersionedSchema {
    static let versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [PlungeSession.self] }
}

enum PlungeSessionSchemaV2: VersionedSchema {
    static let versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [PlungeSession.self] }
}

enum PlungeSessionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PlungeSessionSchemaV1.self, PlungeSessionSchemaV2.self]
    }
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: PlungeSessionSchemaV1.self,
        toVersion: PlungeSessionSchemaV2.self
    )
}
