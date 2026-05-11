import org.apache.hadoop.hdfs.client.HdfsDataInputStream;
import java.lang.reflect.Method;
import java.security.CodeSource;

// Gives debug info about a class
// javac -cp $(hbase classpath) ClassScout.java
// java -cp .:$(hbase classpath) ClassScout
//
// Class Location: file:/opt/hadoop/share/hadoop/hdfs/hadoop-hdfs-client-3.3.6.jar
// Found Method: public org.apache.hadoop.hdfs.ReadStatistics org.apache.hadoop.hdfs.client.HdfsDataInputStream.getReadStatistics()
public class ClassScout {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java -jar methodName");
            System.exit(1)
        }
        try {
            final Class<?> clazz = HdfsDataInputStream.class;   // TODO: hard code?
            final CodeSource src = clazz.getProtectionDomain().getCodeSource();

            System.out.println("Class Location: " + (src != null ? src.getLocation() : "Unknown"));

            boolean found = false;
            for (Method m : clazz.getMethods()) {
                if (m.getName().equals(args[1])) {
                    System.out.println("Found Method: " + m.toString());
                    found = true;
                }
            }
            if (!found)
                System.out.println("METHOD NOT FOUND !!!");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
