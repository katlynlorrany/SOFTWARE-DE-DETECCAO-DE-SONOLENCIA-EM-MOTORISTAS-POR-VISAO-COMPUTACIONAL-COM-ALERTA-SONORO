# Detector de Sonolência para motoristas

App Flutter para detecção de sonolência em motoristas usando ML Kit.

## Como Instalar?

1. Crie um novo projeto Flutter:
   ```
   flutter create detector_sonolencia
   cd detector_sonolencia
   ```

2. Substitua os arquivos pelas versões do ZIP:
   - `lib/main.dart`
   - `pubspec.yaml`
   - `android/app/src/main/AndroidManifest.xml`
   - `android/app/build.gradle.kts`

3. Instale as dependências:
   ```
   flutter pub get
   ```

4. Configure o JDK:
   ```
   flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"
   ```

5. Rode o app:
   ```
   flutter run
   ```

## Dependências
- camera: ^0.11.0
- google_mlkit_face_detection: ^0.11.0
- google_fonts: ^6.1.0

## Como funciona
- Usa a câmera frontal para capturar frames em tempo real
- ML Kit detecta o rosto e retorna a probabilidade de abertura dos olhos
- EAR (Eye Aspect Ratio) abaixo de 0.6 por mais de 5 frames = sonolência
- Barra verde = acordado | laranja = semifechado | vermelho = ALERTA
