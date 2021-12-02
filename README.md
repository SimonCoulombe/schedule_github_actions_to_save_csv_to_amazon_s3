# Well extracts for GWELLS (Groundwater Wells and Aquifers)

## CSV Format notes

[https://docs.python.org/3/library/csv.html:](https://docs.python.org/3/library/csv.html)
> The so-called CSV (Comma Separated Values) format is the most common import and export format for spreadsheets and databases. CSV format was used for many years prior to attempts to describe the format in a standardized way in [RFC 4180](https://tools.ietf.org/html/rfc4180.html). The lack of a well-defined standard means that subtle differences often exist in the data produced and consumed by different applications. These differences can make it annoying to process CSV files from multiple sources. Still, while the delimiters and quoting characters vary, the overall format is similar enough that it is possible to write a single module which can efficiently manipulate such data, hiding the details of reading and writing the data from the programmer.

Well extracts are generated in Python 3 using the csv library "excel" dialect (see [https://docs.python.org/3/library/csv.html#csv.excel](https://docs.python.org/3/library/csv.html#csv.excel))

### Recommendations

It is suggested that you use a mature library, rather than attempting to write bespoke code to read CSV data. For example, [Python 3](https://www.python.org/) comes with module to read and write CSV data.

### Common problems when reading GWELLS CSV data

#### Blank records or data that doesn't match up with columns

It may be that your application does not correctly handle escaped line-break characters. See [RFC 4180, Section 2, point 6](https://tools.ietf.org/html/rfc4180.html#section-2):
>Fields containing line breaks (CRLF), double quotes, and commas should be enclosed in double-quotes. For example:
>
>"aaa","b CRLF
>
>bb","ccc" CRLF
>
>zzz,yyy,xxx

#### Columns/data suddenly no longer available or changed

The data in the well export closely matches the current state of data in the GWELLS web application, as such the structure may change from time to time.

- Column names and positions may change at any time.
- Columns may be added or removed at any time.

## Frequency

Data extracts should be generated daily but may fail to be generated for various reasons.

## Other sources for well information

- XLSX extract, also generated by the [GWELLS](https://apps.nrs.gov.bc.ca/gwells) web application.
- [DataBC](https://data.gov.bc.ca/) provides information sourced from the GWELLS application in various formats.
- API calls directly to the GWELLS application: [https://apps.nrs.gov.bc.ca/gwells/api/](https://apps.nrs.gov.bc.ca/gwells/api/).
