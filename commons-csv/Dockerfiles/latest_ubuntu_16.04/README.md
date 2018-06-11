commons csv (package)

Build and run the container:

$docker build -t commonscsv .
$docker run --name demo_commonscsv -i -t commonscsv /bin/bash

To test the working of Container (try below example)


e.g.
Reading a CSV file (Access Values by Column Index)
The example below shows how you can read and parse the sample CSV file users.csv described above using Apache Commons CSV -


....Input CSV file i.e. users.csv....
Rajeev Kumar Singh ?,rajeevs@example.com,+91-9999999999,India
Sachin Tendulkar,sachin@example.com,+91-9999999998,India
Barak Obama,barak.obama@example.com,+1-1111111111,United States
Donald Trump,donald.trump@example.com,+1-2222222222,United States


....BasicCSVReader.java.................
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import java.io.IOException;
import java.io.Reader;
import java.nio.file.Files;
import java.nio.file.Paths;

public class BasicCSVReader {
    private static final String SAMPLE_CSV_FILE_PATH = "./users.csv";

    public static void main(String[] args) throws IOException {
        try (
            Reader reader = Files.newBufferedReader(Paths.get(SAMPLE_CSV_FILE_PATH));
            CSVParser csvParser = new CSVParser(reader, CSVFormat.DEFAULT);
        ) {
            for (CSVRecord csvRecord : csvParser) {
                // Accessing Values by Column Index
                String name = csvRecord.get(0);
                String email = csvRecord.get(1);
                String phone = csvRecord.get(2);
                String country = csvRecord.get(3);

                System.out.println("Record No - " + csvRecord.getRecordNumber());
                System.out.println("---------------");
                System.out.println("Name : " + name);
                System.out.println("Email : " + email);
                System.out.println("Phone : " + phone);
                System.out.println("Country : " + country);
                System.out.println("---------------\n\n");
            }
        }
    }
}



$ javac BasicCSVReader.java
$ java BasicCSVReader


OUPUT:

Record No - 1
---------------
Name : Rajeev Kumar Singh ?
Email : rajeevs@example.com
Phone : +91-9999999999
Country : India
---------------


Record No - 2
---------------
Name : Sachin Tendulkar
Email : sachin@example.com
Phone : +91-9999999998
Country : India
---------------


Record No - 3
---------------
Name : Barak Obama
Email : barak.obama@example.com
Phone : +1-1111111111
Country : United States
---------------


Record No - 4
---------------
Name : Donald Trump
Email : donald.trump@example.com
Phone : +1-2222222222
Country : United States
---------------


Record No - 1
---------------
Name : Rajeev Kumar Singh ?
Email : rajeevs@example.com
Phone : +91-9999999999
Country : India
---------------


Record No - 2
---------------
Name : Sachin Tendulkar
Email : sachin@example.com
Phone : +91-9999999998
Country : India
---------------


Record No - 3
---------------
Name : Barak Obama
Email : barak.obama@example.com
Phone : +1-1111111111
Country : United States
---------------


Record No - 4
---------------
Name : Donald Trump
Email : donald.trump@example.com
Phone : +1-2222222222
Country : United States
---------------


Additional examples are available at: https://www.callicoder.com/java-read-write-csv-file-apache-commons-csv/

