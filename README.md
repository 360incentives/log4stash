log4stash
=====================

log4stash is a [log4net](http://logging.apache.org/log4net/) appender to log messages to the [ElasticSearch](http://www.elasticsearch.org) document database. ElasticSearch offers robust full-text search engine and analyzation so that errors and messages can be indexed quickly and searched easily.

log4stash provide few logging filters similar to the filters on [logstash](http://logstash.net).

The origin of log4stash is [@jptoto](https://github.com/jptoto)'s [log4net.ElasticSearch](https://github.com/jptoto/log4net.ElasticSearch) repository.

### Features:
* Supports .NET 3.5+ (see [Supported target frameworks](#supported-target-frameworks) — .NET 4.5 and below are maintenance-only)
* Easy installation and setup via [Nuget](https://nuget.org/packages/log4stash/)
* Ability to analyze the log event before sending it to elasticsearch using built-in filters and custom filters similar to [logstash](http://logstash.net/docs/1.4.2/).

### Supported target frameworks:

`log4stash` ships as a single NuGet package containing one assembly per target framework. NuGet
picks the folder matching your project, so a net462-or-later project automatically gets the build
that depends on the maintained log4net 3.x line.

| Project | TFM | log4net | Support status |
| ------- | --- | ------- | -------------- |
| `log4net.ElasticSearch` | `net462` | 3.3.2 | **Actively maintained — recommended default** |
| `log4net.ElasticSearch.net40` | `net40` | 2.0.15 | Maintenance only |
| `log4net.ElasticSearch.net35` | `net35` | 2.0.15 | Maintenance only |

There is **no net45 assembly**. Projects targeting `net45` through `net461` resolve the `net40`
build (the nearest compatible folder) and therefore also run on log4net 2.0.15. Earlier releases
shipped a purpose-built net45 assembly, so this is a downgrade for those consumers — retarget to
`net462` or later to get the maintained build.

#### :warning: Security note on the legacy targets

The `net40` and `net35` targets are **maintenance-only** and are pinned to log4net
**2.0.15**. This is not a choice we can revisit: log4net 3.x ships only `net462` and
`netstandard2.0` assemblies, so there is no log4net 3.x build for those frameworks.

Consequently the legacy targets **inherit every known log4net 2.0.15 vulnerability and cannot
receive log4net security fixes**. At time of writing that includes
[CVE-2026-40021 / GHSA-4f7c-pmjv-c25w](https://github.com/advisories/GHSA-4f7c-pmjv-c25w)
(moderate, CVSS v4 6.3): `XmlLayout` and `XmlLayoutSchemaLog4J` fail to sanitize characters
forbidden by XML 1.0, so attacker-controlled data in an MDC property or identity field causes a
serialization failure and the log event is **silently dropped** — allowing an attacker to suppress
individual audit records. Fixed in log4net 3.3.0.

Note that log4stash itself does not use `XmlLayout` (it serializes events with `Newtonsoft.Json`),
so the appender does not trigger that advisory on its own. You are exposed only if your application
*also* configures an XmlLayout-based appender.

#### Migrating to the modern package

No code or configuration changes are required — the appender's public API and its XML configuration
schema are identical across all four targets, and all four are compiled from the same source files.

1. Retarget your application to `net462` or later.
2. Reinstall/restore `log4stash`. NuGet will resolve `lib/net462` and pull log4net **3.3.2** instead
   of 2.0.15.
3. Remove any `<bindingRedirect>` for `log4net` that pinned `2.0.15.0` (`oldVersion` up to
   `2.0.15.0`), since the assembly identity moves to the 3.x line.
4. If you subclass `BasicLogEventFactory` or implement `IElasticAppenderFilter`, rebuild against the
   net462 assembly. The interfaces are unchanged, but the referenced log4net identity is not.

Staying on a legacy target is supported but means accepting the log4net 2.0.15 risk described above.

### Building:

`log4net.ElasticSearch` (net462) is the default build and the one that is expected to build and test
cleanly. The two legacy projects require the matching .NET Framework targeting packs
(`v3.5`, `v4.0`) to be installed on the build machine; without them MSBuild fails with
`MSB3644`. They are not built on CI — see [Build status](#build-status).

All projects compile from the same source files, which use C# 6 syntax (`?.`), so a Roslyn
compiler (VS 2015 / MSBuild 14 or later) is required even for the net35 and net40 targets.

### Breaking Changes:
* The definition of IElasticAppenderFilter has been changed, PrepareEvent has only one parameter and PrepareConfiguration's parameter type has changed to IElasticsearchClient.

#### :green_book: Version 1.1.0 note:
* log4stash 1.1.0 has new feature `SerializeObjects`, if true (the default) it serializes the exception object and message object into json object and add them to Elastic. You can see them under "MessageObject" and "ExceptionObject" keys.  - [Related commit](https://github.com/urielha/log4stash/commit/560676de9b074be70e00f93566c543a846ba5c8e)

### Filters:
* **Add** - add new key and value to the event.
* **Remove** - remove key from the event.
* **Rename** - rename key to another name.
* **Kv** - analyze value (default is to analyze the 'Message' value) and export key-value pairs using regex (similar to logstash's kv filter).
* **Grok** - analyze value (default is 'Message') using custom regex and saved patterns (similar to logstash's grok filter).
* **ConvertToArray** - split raw string to an array by given seperators. 

#### Custom filter:
To add your own filters you just need to implement the interface IElasticAppenderFilter on your assembly and configure it on the log4net configuration file.

<!-- ### Usage:
Please see the [DOCUMENTATION](https://github.com/urielha/log4net.ElasticSearch/wiki/0-Documentation) Wiki page to begin logging errors to ElasticSearch! -->

### Issues:
I do my best to reply to issues or questions ASAP. Please use the [ISSUES](https://github.com/urielha/log4stash/issues) page to submit questions or errors.

### Configuration Examples:

Almost all the parameters are optional, to see the default values check the [c'tor](https://github.com/urielha/log4stash/blob/master/src/log4net.ElasticSearch/ElasticSearchAppender.cs#L52) of the appender and the c'tor of every filter. 
You can also set any public property in the appender/filter which didn't appear in the example.

##### Simple configuration:
```xml
<appender name="ElasticSearchAppender" type="log4net.ElasticSearch.ElasticSearchAppender, log4stash">
    <Server>localhost</Server>
    <Port>9200</Port>
    <ElasticFilters>
      <!-- example of using filter with default parameters -->
      <kv /> 
    </ElasticFilters>
</appender>
```

##### (Almost) Full configuration:
```xml
<appender name="ElasticSearchAppender" type="log4net.ElasticSearch.ElasticSearchAppender, log4stash">
    <Server>localhost</Server>
    <Port>9200</Port>
    <IndexName>log_test_%{+yyyy-MM-dd}</IndexName>
    <IndexType>LogEvent</IndexType>
    <Bulksize>2000</Bulksize>
    <BulkIdleTimeout>10000</BulkIdleTimeout>
    <IndexAsync>False</IndexAsync>

    <!-- for more information read about log4net.Core.FixFlags -->
    <FixedFields>Partial</FixedFields>
    
    <Template>
      <Name>templateName</Name>
      <FileName>path2template.json</FileName>
    </Template>

    <!-- all filters goes in ElasticFilters tag -->
    <ElasticFilters>
      <Add>
        <Key>@type</Key>
        <Value>Special</Value>
      </Add>

      <!-- using the @type value from the previous filter -->
      <Add>
        <Key>SmartValue</Key>
        <Value>the type is %{@type}</Value>
      </Add>

      <Remove>
        <Key>@type</Key>
      </Remove>

      <!-- you can load custom filters like I do here -->
      <Filter type="log4net.ElasticSearch.Filters.RenameKeyFilter, log4stash">
        <Key>SmartValue</Key>
        <RenameTo>SmartValue2</RenameTo>
      </Filter>

      <!-- kv and grok filters similar to logstash's filters -->
      <Kv>
      	<SourceKey>Message</SourceKey>
      	<ValueSplit>:=</ValueSplit>
      	<FieldSplit> ,</FieldSplit>
      </kv>

      <Grok>
        <SourceKey>Message</SourceKey>
        <Pattern>the message is %{WORD:Message} and guid %{UUID:the_guid}</Pattern>
        <Overwrite>true</Overwrite>
      </Grok>
    </ElasticFilters>
</appender>
```

Note that the filters got called by the order they appeared in the config (as shown in the example).

### License:
[MIT License](https://github.com/urielha/log4net.ElasticSearch/blob/master/LICENSE)

### Thanks:
Thanks to [@jptoto](https://github.com/jptoto) for the idea and the first working ElasticAppender.
Many thanks to [@mpdreamz](https://github.com/Mpdreamz) and the team for their great work on the NEST library!
The inspiration to the filters and style had taken from [elasticsearch/logstash](https://github.com/elasticsearch/logstash) project.

### Build status:

| Status | Provider |
| ------ | -------- |
| [![Build status][TravisImg]][TravisLink] | Mono CI provided by [travis-ci][] |
| [![Build Status][AppVeyorImg]][AppVeyorLink] | Windows CI provided by [AppVeyor][] (without tests for now) |

[TravisImg]:https://travis-ci.org/urielha/log4stash.svg?branch=master
[TravisLink]:https://travis-ci.org/urielha/log4stash
[AppVeyorImg]:https://ci.appveyor.com/api/projects/status/byp4s7vl8cuhyae0
[AppVeyorLink]:https://ci.appveyor.com/project/urielha/log4stash

[travis-ci]:https://travis-ci.org/
[AppVeyor]:http://www.appveyor.com/
