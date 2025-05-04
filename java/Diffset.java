import java.io.IOException;
import java.nio.file.*;
import java.util.Set;
import java.util.stream.*;

public class Diffset {
    public static void main(String[] args) throws IOException {
        if (args.length != 3) {
            System.err.println("Usage:   java -jar diffset.jar file1 op file2\nwhere op = [intersect, union, diff]\n\nExample: java -jar diffset.jar a.txt intersect b.txt       # shows intersection of 2 files, a.txt and b.txt");
            System.exit(1);
        }

        final String file1 = args[0];
        final String op    = args[1];
        final String file2 = args[2];

        try (final Stream<String> lines1 = Files.lines(Paths.get(file1)).map(String::trim).filter(t -> !t.isEmpty())) {
            try (final Stream<String> lines2 = Files.lines(Paths.get(file2)).map(String::trim).filter(t -> !t.isEmpty())) {
                final Set<String> s1 = lines1.collect(Collectors.toSet());
                final Set<String> s2 = lines2.collect(Collectors.toSet());
                final int s1size = s1.size();
                final int s2size = s2.size();
                switch (op) {
                    case "intersect":
                        s1.retainAll(s2);
                        break;
                    case "union":
                        s1.addAll(s2);
                        break;
                    case "diff":
                        s1.removeAll(s2);
                        break;
                    default:
                        System.err.printf("Unknown operation %s (only 'intersect', 'union' and 'diff' allowed)\n", op);
                        System.exit(1);
                }
                s1.forEach(System.out::println);
                System.out.printf("\nSet1 contains %d unique elements\n", s1size);
                System.out.printf("Set2 contains %d unique elements\n", s2size);
                System.out.printf("Result set contains %d unique elements\n", s1.size());
            }
        }
    }
}
