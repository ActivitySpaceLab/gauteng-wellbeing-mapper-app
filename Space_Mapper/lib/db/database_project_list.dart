import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../external_projects/tiger_in_car/models/project_list.dart';

class ProjectDatabaseList {
  static final ProjectDatabaseList instance = ProjectDatabaseList._init();

  static Database? _database;

  ProjectDatabaseList._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('project_storage.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final stringType = 'TEXT NOT NULL';
    final nullStringType = 'TEXT';

    await db.execute('''
    CREATE TABLE $tableProject (
      ${ProjectFields.projectId} $idType,
      ${ProjectFields.projectName} $stringType,
      ${ProjectFields.projectDescription} $stringType,
      ${ProjectFields.externalLink} $nullStringType,
      ${ProjectFields.internalLink} $nullStringType,
      ${ProjectFields.projectImageLocation} $stringType,
      ${ProjectFields.locationSharingMethod} INTEGER NOT NULL,
      ${ProjectFields.surveyElementCode} $stringType,
      ${ProjectFields.projectURL} $stringType
    )
    ''');
  }

  Future<ProjectList> createProject(ProjectList project) async {
    final db = await instance.database;
    final id = await db.insert(tableProject, project.toJson());
    return project.copy(projectId: id);
  }

  Future<ProjectList> readProject(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableProject,
      columns: ProjectFields.values,
      where: '${ProjectFields.projectId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ProjectList.fromJson(maps.first);
    } else {
      throw Exception('Project ID $id not found');
    }
  }

  Future<List<ProjectList>> readAllProjects() async {
    final db = await instance.database;
    final result = await db.query(tableProject);
    return result.map((json) => ProjectList.fromJson(json)).toList();
  }

  Future<int> updateProject(ProjectList project) async {
    final db = await instance.database;
    return db.update(
      tableProject,
      project.toJson(),
      where: '${ProjectFields.projectId} = ?',
      whereArgs: [project.projectId],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableProject,
      where: '${ProjectFields.projectId} = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
