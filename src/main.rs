extern crate chrono;
use git2::Repository;
use git2::{Error, Commit};
use chrono::prelude::*;

fn run() -> Result<(), Error> {
    let repo = Repository::open(".")?;
    let head = repo.head()?.peel_to_commit()?;
    let parent = head.parents().next().ok_or(Error::from_str("orphan"))?;

    let parent_epoch = epoch(&parent);

    println!("parent:{}", parent.id());
    println!("epoch:{}", parent_epoch);

    let mut references = repo.references()?;
    loop {
        match references.next() {
            Some(some_ref) => {
                let commit = some_ref?.peel_to_commit()?;
                let commit_epoch = epoch(&commit);
                let sha1 = &(commit.id().to_string())[..6];
                print!("{} ", sha1);
                print!("{} ", commit_epoch);
                println!("{}",
                    commit.summary().ok_or(Error::from_str("no summary"))?);
                if epoch(&commit) == parent_epoch {
                    println!("  match:{}", sha1);
                }

            }
            None => { break }
        }
    }

    Ok(())
}

fn epoch(commit: &Commit) -> DateTime<Utc> {
    let author = commit.author();
    let timestamp = author.when();
    let epoch = timestamp.seconds();
    // let offset = timestamp.offset_minutes();
    let naive_datetime = NaiveDateTime::from_timestamp(epoch, 0);
    let datetime: DateTime<Utc>
        = DateTime::from_utc(naive_datetime, Utc);
    datetime
}

fn main() {
    match run() {
        Ok(()) => {}
        Err(e) => println!("error: {}", e),
    }
}
