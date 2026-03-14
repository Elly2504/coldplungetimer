import SwiftData

enum PlungeSessionSchemaV1: VersionedSchema {
    static let versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [PlungeSession.self] }
}

enum PlungeSessionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [PlungeSessionSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
