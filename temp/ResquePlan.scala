import scala.sys.process._
import java.io.File
import scala.io.Source
import scala.util.Try

object RescuePlan {

  def main(args: Array[String]): Unit = {
    val branchesFile = "branches.txt"
    
    if (!new File(branchesFile).exists()) {
      println(s"❌ Error: Code requires '$branchesFile' to exist in the current directory.")
      sys.exit(1)
    }

    println("🚀 Starting proactive branch rescue audit...\n")

    // Read branches from file, trimming whitespace and ignoring empty lines
    val branches = Source.fromFile(branchesFile).getLines()
      .map(_.trim)
      .filter(_.nonEmpty)
      .toList

    branches.foreach { br =>
      println(s"--------------------------------------------------")
      println(s"🔍 Auditing branch: $br")
      
      val missingFiles = findMissingFiles(br)
      
      if (missingFiles.nonEmpty) {
        println(s"⚠️  🚨 FOUND ${missingFiles.size} REALLY MISSING FILES:")
        missingFiles.foreach(file => println(s"   - $file"))
      } else {
        println(s"✅ Branch is clean or unaffected.")
      }
    }
    
    println(s"--------------------------------------------------")
    println("🏁 Audit complete!")
  }

  def findMissingFiles(br: String): Set[String] = {
    // 1. Get files active in the feature branch relative to develop_SDP
    val cmdActiveFiles = Seq("git", "diff", "--name-only", s"develop_SDP...$br")
    val activeFiles = runCommand(cmdActiveFiles)

    // 2. Get files dropped/gone between the backup branch and broken origin tip
    val cmdDroppedFiles = Seq("git", "diff", "--name-only", "--diff-filter=D", s"backup/$br", s"origin/$br")
    val droppedFiles = runCommand(cmdDroppedFiles)

    // 3. Find the intersection of both sets
    activeFiles.intersect(droppedFiles)
  }

  // Helper to execute git shell commands safely and collect output lines
  private def runCommand(command: Seq[String]): Set[String] = {
    Try {
      command.lineStream.toSet
    }.getOrElse {
      // Return empty set if the branch doesn't exist in backup or origin yet
      Set.empty[String]
    }
  }
}
