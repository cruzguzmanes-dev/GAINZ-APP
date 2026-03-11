# Contexto del Proyecto - Timer de Entrenamiento con Aprendizaje de Idiomas

## Resumen Ejecutivo
Aplicación de timer para entrenamientos que aprovecha los descansos entre series para mostrar contenido educativo de idiomas (vocabulario, phrasal verbs, idioms). El usuario aprende mientras descansa durante su rutina de ejercicio.

## Plataformas
- **watchOS** (Producto Principal) - Apple Watch
- **iOS** - iPhone (App complementaria)

## Funcionalidades Principales

### Apple Watch (Producto Principal)
- ⏱️ **Timer de descanso**: Intervalos configurables (30s, 1min, 2min, etc.)
- 📇 **Sistema de Cards**: Muestra contenido educativo durante el descanso
  - Vocabulario
  - Phrasal Verbs
  - Idioms
- 🔄 **Navegación por Swipe**: El usuario puede deslizar para ver la siguiente card
- 🌐 **Contenido Bilingüe**: Cada card muestra:
  - Palabra/frase en el idioma que se estudia
  - Traducción/significado

### iPhone (App Complementaria)
- 📦 **Gestión de Paquetes**: Agregar más paquetes de contenido
- ✏️ **Creación de Contenido Personalizado**: 
  - El usuario puede crear sus propias cards
  - Permite estudiar contenido específico según necesidades personales
- ⚙️ **Configuración y Sincronización**: Gestión del contenido que aparece en el Watch

## Stack Tecnológico
- **Lenguaje**: Swift
- **UI Framework**: SwiftUI
- **Plataformas**: 
  - watchOS (principal)
  - iOS (complementaria)
- **Sincronización**: Watch Connectivity Framework
- **Persistencia de Datos**: (Por definir: SwiftData, Core Data, o archivos JSON locales)

## Arquitectura
- **Patrón de Diseño**: (Por definir - recomendado MVVM para SwiftUI)
- **Modelos de Datos**:
  - `Card`: Contenido educativo individual
  - `ContentPackage`: Paquete de cards agrupadas
  - `TimerSession`: Configuración del timer
  - `Language`: Idioma de estudio

## Estructura de Datos (Propuesta)

### Card
```swift
- id: UUID
- term: String (palabra/frase en idioma de estudio)
- definition: String (significado)
- translation: String (traducción)
- type: CardType (vocabulary, phrasal verb, idiom)
- language: Language
```

### ContentPackage
```swift
- id: UUID
- name: String
- cards: [Card]
- isCustom: Bool (si fue creado por el usuario)
- language: Language
```

### TimerSession
```swift
- duration: TimeInterval (30s, 1min, 2min, etc.)
- currentPackage: ContentPackage
- currentCardIndex: Int
```

## Estado Actual del Proyecto
- ✅ Concepto y arquitectura básica definida
- 🚧 En desarrollo: Apple Watch Timer con Cards
- 🚧 En desarrollo: iPhone - Gestión de paquetes
- 🚧 En desarrollo: iPhone - Creación de contenido personalizado
- ⏳ Pendiente: Sincronización entre dispositivos
- ⏳ Pendiente: Persistencia de datos

## Flujo de Usuario

### En el Apple Watch:
1. Usuario inicia una sesión de entrenamiento
2. Configura tiempo de descanso (30s, 1min, 2min, etc.)
3. Durante el descanso, aparecen cards con contenido educativo
4. Usuario puede hacer swipe para ver más cards
5. El timer continúa hasta completar el descanso

### En el iPhone:
1. Usuario explora paquetes de contenido disponibles
2. Descarga/activa paquetes adicionales
3. Crea contenido personalizado:
   - Añade términos personalizados
   - Define traducciones
   - Organiza en paquetes custom
4. Sincroniza con Apple Watch

## Características Técnicas Importantes

### watchOS
- Interfaz optimizada para pantalla pequeña
- Gestos de swipe para navegación
- Timer preciso y visible
- Bajo consumo de batería durante entrenamiento

### iOS
- Editor de contenido intuitivo
- Gestión de múltiples idiomas
- Import/Export de paquetes (futuro)
- Preview del contenido

## Idiomas Soportados
- (Por definir lista de idiomas disponibles)
- Sistema debe ser extensible para agregar más idiomas

## Próximos Pasos
1. Definir modelo de datos definitivo
2. Implementar persistencia (SwiftData recomendado)
3. Completar UI del timer en watchOS
4. Implementar sistema de swipe en cards
5. Desarrollar editor de contenido en iOS
6. Implementar Watch Connectivity
7. Testing en dispositivos reales

## Notas de Desarrollo
- Priorizar experiencia en Apple Watch (producto principal)
- Mantener UI simple y legible durante ejercicio
- Considerar accesibilidad (VoiceOver, Dynamic Type)
- Optimizar para uso con manos sudorosas/con guantes
- El contenido debe ser fácil de leer con un vistazo rápido

## Convenciones de Código
- Swift moderno con concurrency (async/await)
- SwiftUI para todas las interfaces
- Documentación en español para contexto de negocio
- Código y comentarios técnicos en inglés (convención estándar)

---
**Última actualización**: Marzo 2026
**Versión del documento**: 1.0
