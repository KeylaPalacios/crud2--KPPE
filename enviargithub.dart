import 'dart:io';

void main() async {
  print('--------------------------------------------------');
  print('   AGENTE INTERACTIVO DE DESPLIEGUE A GITHUB      ');
  print('--------------------------------------------------');

  // 1. Preguntar por el link del repositorio
  stdout.write('1. Ingrese el link del nuevo repositorio de GitHub: ');
  String? repoUrl = stdin.readLineSync()?.trim();
  
  if (repoUrl == null || repoUrl.isEmpty) {
    print('Error: El link del repositorio es obligatorio.');
    return;
  }

  // 2. Preguntar por el mensaje de commit
  stdout.write('2. Ingrese el mensaje para el commit: ');
  String? commitMessage = stdin.readLineSync()?.trim();
  
  if (commitMessage == null || commitMessage.isEmpty) {
    print('Error: El mensaje de commit es obligatorio.');
    return;
  }

  // 3. Preguntar por la rama (default main)
  stdout.write('3. Ingrese el nombre de la rama (presione Enter para "main"): ');
  String? branchInput = stdin.readLineSync()?.trim();
  String branch = (branchInput == null || branchInput.isEmpty) ? 'main' : branchInput;
  
  // Limpiar el nombre de la rama (reemplazar espacios por guiones)
  branch = branch.replaceAll(' ', '-');
  if (branch != branchInput && branchInput != null && branchInput.isNotEmpty) {
    print('Nota: El nombre de la rama se ajustó a "$branch" (sin espacios).');
  }

  print('\n--- Iniciando Comandos de Git ---\n');

  try {
    // 1. Git Init
    bool gitExists = await Directory('.git').exists();
    if (!gitExists) {
      await _runCommand('git', ['init'], 'Inicializando repositorio...');
    }

    // 2. Git Add
    await _runCommand('git', ['add', '.'], 'Agregando archivos...');
    
    // 3. Git Commit (manejar si no hay cambios)
    print('>> Creando commit...');
    ProcessResult commitResult = await Process.run('git', ['commit', '-m', commitMessage]);
    if (commitResult.exitCode != 0) {
      if (commitResult.stdout.toString().contains('nothing to commit') || 
          commitResult.stderr.toString().contains('nothing to commit')) {
        print('Aviso: No hay cambios nuevos para subir.');
      } else {
        print('Error en commit: ${commitResult.stderr}');
        return;
      }
    } else {
      print('Commit creado con éxito.');
    }
    
    // 4. Git Branch
    await _runCommand('git', ['branch', '-M', branch], 'Configurando rama "$branch"...');

    // 5. Git Remote
    await Process.run('git', ['remote', 'remove', 'origin']);
    await _runCommand('git', ['remote', 'add', 'origin', repoUrl], 'Conectando con remoto...');
    
    // 6. Git Push
    print('>> Subiendo a GitHub...');
    ProcessResult pushResult = await Process.run('git', ['push', '-u', 'origin', branch]);
    
    if (pushResult.exitCode != 0) {
      String error = pushResult.stderr.toString();
      if (error.contains('403') || error.contains('denied')) {
        print('\n--- ERROR DE PERMISOS ---');
        print('Tu computadora está usando la cuenta de OTRA persona.');
        print('Para solucionarlo, copia y pega este comando en tu terminal:');
        print('git credential-manager reject https://github.com');
        print('Luego vuelve a ejecutar este script.');
      } else {
        print('Error en push: $error');
      }
    } else {
      print('\n¡TODO LISTO! Código subido correctamente.');
    }

  } catch (e) {
    print('\n[ERROR]: $e');
  }
}

Future<void> _runCommand(String command, List<String> args, String message) async {
  print('>> $message');
  ProcessResult result = await Process.run(command, args);
  if (result.exitCode != 0) {
    throw Exception('Fallo el comando: $command ${args.join(' ')}\nDetalle: ${result.stderr}');
  }
}
