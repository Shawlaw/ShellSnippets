# Gradle Script

## Simple implementation of adding generated BuildCfg class in pure java project

1. Copy the script content of *addBuildCfgInJavaProject.gradle* to your gradle script
2. Use following code in your gradle script to add fields to BuildCfg class, take BuildCfg.TIME and BuildCfg.NAME as examples
```java
new Field("long", "TIME", System.currentTimeMillis() + "L").addToMap(buildCfgs)
new Field("String", "NAME", "\"Shawlaw\"").addToMap(buildCfgs)
```
3. Then you can use BuildCfg.TIME and BuildCfg.NAME in your java code